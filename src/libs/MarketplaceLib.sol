// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ContextLib} from "@diamond/libraries/ContextLib.sol";
import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ACCOUNT_V3_IMPLEMENTATION, ERC6551_REGISTRY} from "@ticket-script/helpers/AddressesAndFees.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {ExtraTicketData, FactoryLib} from "@ticket/libs/FactoryLib.sol";
import {IERC6551Registry} from "erc6551/src/interfaces/IERC6551Registry.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

event TicketFeeSet(uint64 indexed ticketId, FeeType[] feeType, uint256[] fee); // ticketId:{ticketId}, fee:{tok}

event TicketRefunded(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event TicketFeeAddressSet(FeeType[] feeType, address[] token); // token:{addr}

event TicketMinted(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, uint40 tokenId); // fee:{tok}, tokenId:{ticket}

event TicketBalanceWithdrawn(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event HostItBalanceWithdrawn(FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event FiatTicketMinted(
    uint64 indexed ticketId, address indexed buyer, uint40 tokenId, uint256 amount, bytes32 indexed paymentId
); // amount:{fiat}, tokenId:{ticket}

event TrustedBackendUpdated(address indexed previous, address indexed current);

error PurchaseTimeNotReached();
error TicketSoldOut();
error MaxTicketsHeld();
error TokenAddressZero();
error InvalidFeeConfig();
error ZeroFee(FeeType);
error TicketIsFree();
error FeeNotEnabled(uint64, FeeType);
error InsufficientBalance(address, FeeType, uint256);
error InsufficientAllowance(address, FeeType, uint256);
error RefundNotEnabled();
error RefundPeriodNotReached();
error RefundPeriodExpired();
error WithdrawPeriodNotReached();
error InsufficientWithdrawBalance();
error TicketNotOwned(uint256);
error InsufficientPayment(FeeType, uint256);
error PaymentFailed(FeeType, uint256);
error TicketAccountingMismatch();
error CreateERC6551AccountFailed();
error UnauthorizedBackend();
error InvalidVoucherSignature();
error VoucherExpired();
error PaymentIdAlreadyUsed(bytes32);
error InvalidPaymentId();
error ZeroFiatAmount();
error FiatTicketNotRefundable();
error FiatBalanceNotWithdrawable();
error FiatFeeTypeNotMintable();
error FiatFeeNotSettable();
error BatchLengthMismatch();

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.marketplace.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant MARKETPLACE_STORAGE_LOCATION = 0x3f09c55b469305b27ecae2a46b3f364669f622316549d801837d9eeba9778d00;

/// @title FeeType
/// @notice Enum for fee types.
enum FeeType {
    NONE,
    NATIVE,
    WNATIVE,
    USDT,
    USDC,
    USDT0,
    EURC,
    GHO,
    LINK,
    LSK,
    FIAT
}

/// @title FiatVoucher
/// @notice Backend-signed authorization for an off-chain fiat purchase, redeemable on-chain.
/// @dev Bound to chain + verifying contract via the EIP-712 domain.
struct FiatVoucher {
    uint64 ticketId;
    address buyer;
    uint256 amount; // {fiat} smallest fiat unit charged (e.g. cents)
    bytes32 paymentId; // backend-generated, globally unique
    uint48 expiresAt; // {s}
}

/// @title MarketplaceStorage
/// @notice Storage structure for managing marketplace data. Fields below the divider were appended for the
///         off-chain fiat payment feature; further fields must continue to be appended (ERC-7201 invariant).
/// @custom:storage-location erc7201:host.it.ticket.marketplace.storage
struct MarketplaceStorage {
    mapping(uint64 => mapping(FeeType => uint256)) ticketFee; // {ticketId} => FeeType => {tok}
    mapping(uint64 => mapping(FeeType => uint256)) ticketBalance; // {ticketId} => FeeType => {tok}
    mapping(FeeType => address) feeTokenAddress; // FeeType => {addr}
    mapping(FeeType => uint256) hostItBalance; // FeeType => {tok}
    // --- FIAT storage ---
    address trustedBackend; // owner-managed signer + direct caller
    mapping(bytes32 => bool) usedFiatPaymentIds; // replay guard
    mapping(uint64 => mapping(uint40 => bool)) isFiatPaidToken; // (ticketId, tokenId) => fiat-paid flag
    mapping(uint64 => uint256) ticketFiatRevenue; // {ticketId} => {fiat} lifetime fiat revenue
}

library MarketplaceLib {
    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    uint256 internal constant REFUND_PERIOD = 3 days; // {s}
    uint256 private constant HOSTIT_FEE_BPS = 300; // BPS{1} 3% fee in basis points
    uint256 private constant FEE_BASIS_POINTS = 10_000; // BPS{1} 10,000 basis points

    bytes32 internal constant FIAT_VOUCHER_TYPEHASH =
        keccak256("FiatVoucher(uint64 ticketId,address buyer,uint256 amount,bytes32 paymentId,uint48 expiresAt)");
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant EIP712_NAME_HASH = keccak256(bytes("HostItTickets"));
    bytes32 private constant EIP712_VERSION_HASH = keccak256(bytes("1"));

    function marketplaceStorage() internal pure returns (MarketplaceStorage storage ms_) {
        assembly {
            ms_.slot := MARKETPLACE_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @param _ticketId {ticketId}
    /// @param _buyer {addr}
    /// @return tokenId_ {ticket}
    function mintTicket(uint64 _ticketId, FeeType _feeType, address _buyer) internal returns (uint40 tokenId_) {
        if (_feeType == FeeType.FIAT) revert FiatFeeTypeNotMintable();

        ExtraTicketData memory ticketData = _preMintChecks(_ticketId, _buyer);

        address msgSender = ContextLib.msgSender();
        MarketplaceStorage storage ms = marketplaceStorage();
        // {tok}, {tok}, {tok}
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = getFees(ms, _ticketId, _feeType);
        if (!ticketData.isFree) {
            if (!feeEnabled(ms, _ticketId, _feeType)) revert FeeNotEnabled(_ticketId, _feeType);

            ms.hostItBalance[_feeType] += hostItFee; // {tok} += {tok}
            if (ticketData.isRefundable) {
                if (_feeType == FeeType.NATIVE) {
                    // {tok} < {tok}
                    if (msg.value < totalFee) {
                        revert InsufficientPayment(_feeType, totalFee);
                    }
                    // Refund excess NATIVE if user overpays
                    if (msg.value > totalFee) {
                        SafeTransferLib.forceSafeTransferETH(msgSender, msg.value - totalFee);
                    }
                } else {
                    _payWithToken(ms, _feeType, totalFee, address(this));
                }
                ms.ticketBalance[_ticketId][_feeType] += fee; // {tok} += {tok}
            } else {
                if (_feeType == FeeType.NATIVE) {
                    // {tok} < {tok}
                    if (msg.value < totalFee) {
                        revert InsufficientPayment(_feeType, totalFee);
                    }
                    // Refund excess NATIVE if user overpays
                    if (msg.value > totalFee) {
                        SafeTransferLib.forceSafeTransferETH(msgSender, msg.value - totalFee);
                    }
                    SafeTransferLib.forceSafeTransferETH(ticketData.ticketAdmin, fee);
                } else {
                    _payWithToken(ms, _feeType, fee, ticketData.ticketAdmin);
                    _payWithToken(ms, _feeType, hostItFee, address(this));
                }
            }
        }

        tokenId_ = _finalizeMint(ticketData, _buyer, _feeType, totalFee);
    }

    /// @param _ticketId {ticketId}
    /// @param _fees {tok} per-ticket price in each fee token
    function updateTicketFees(uint64 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        FactoryLib.checkTicketExists(_ticketId);
        if (FactoryLib.factoryStorage().ticketIdToData[_ticketId].isFree) revert TicketIsFree();
        setTicketFees(_ticketId, _feeTypes, _fees);
    }

    function setTicketFees(uint64 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees) internal {
        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength == 0 || feeTypesLength != _fees.length) {
            revert InvalidFeeConfig();
        }

        MarketplaceStorage storage ms = marketplaceStorage();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_feeTypes[i] == FeeType.FIAT) revert FiatFeeNotSettable();
            if (_fees[i] == 0) revert ZeroFee(_feeTypes[i]);

            ms.ticketFee[_ticketId][_feeTypes[i]] = _fees[i]; // {tok}
        }

        emit TicketFeeSet(_ticketId, _feeTypes, _fees);
    }

    /// @param _ticketId {ticketId}
    /// @param _tokenId {ticket}
    function claimRefund(uint64 _ticketId, FeeType _feeType, uint256 _tokenId) internal {
        claimRefund(_ticketId, _feeType, _tokenId, ContextLib.msgSender());
    }

    /// @param _ticketId {ticketId}
    /// @param _tokenId {ticket}
    /// @param _to {addr}
    function claimRefund(uint64 _ticketId, FeeType _feeType, uint256 _tokenId, address _to) internal {
        FactoryLib.checkTicketExists(_ticketId);

        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);

        MarketplaceStorage storage ms = marketplaceStorage();
        if (ms.isFiatPaidToken[_ticketId][SafeCastLib.toUint40(_tokenId)]) {
            revert FiatTicketNotRefundable();
        }

        if (!ticketData.isRefundable) revert RefundNotEnabled();

        uint48 time = SafeCastLib.toUint48(block.timestamp); // {s}
        if (time < ticketData.endTime) revert RefundPeriodNotReached(); // {s} < {s}
        // {s} > {s} + {s}
        if (time > ticketData.endTime + REFUND_PERIOD) {
            revert RefundPeriodExpired();
        }

        address caller = ContextLib.msgSender(); // {addr}
        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (caller != ticket.ownerOf(_tokenId)) revert TicketNotOwned(_tokenId); // {addr} != {addr}

        uint256 ticketFee = getTicketFee(_ticketId, _feeType); // {tok}
        ms.ticketBalance[_ticketId][_feeType] -= ticketFee; // {tok} -= {tok}

        ticket.refundTicket(ticketData.ticketAdmin, _tokenId);

        if (_feeType == FeeType.NATIVE) {
            SafeTransferLib.safeTransferETH(_to, ticketFee);
        } else {
            SafeTransferLib.safeTransfer(getFeeTokenAddress(_feeType), _to, ticketFee);
        }

        emit TicketRefunded(_ticketId, _feeType, ticketFee, _to);
    }

    /// @param _ticketId {ticketId}
    /// @param _to {addr}
    function withdrawTicketBalance(uint64 _ticketId, FeeType _feeType, address _to)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        if (_feeType == FeeType.FIAT) revert FiatBalanceNotWithdrawable();

        FactoryLib.checkTicketExists(_ticketId);
        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);

        if (ticketData.isRefundable) {
            // {s} < {s} + {s}
            if (SafeCastLib.toUint48(block.timestamp) < ticketData.endTime + REFUND_PERIOD) {
                revert WithdrawPeriodNotReached();
            }
        }

        uint256 balance = getTicketBalance(_ticketId, _feeType); // {tok}
        if (balance == 0) revert InsufficientWithdrawBalance();
        delete marketplaceStorage().ticketBalance[_ticketId][_feeType];

        if (_feeType == FeeType.NATIVE) {
            SafeTransferLib.forceSafeTransferETH(_to, balance);
        } else {
            SafeTransferLib.safeTransfer(getFeeTokenAddress(_feeType), _to, balance);
        }

        emit TicketBalanceWithdrawn(_ticketId, _feeType, balance, _to);
    }

    /// @param _to {addr}
    function withdrawHostItBalance(FeeType _feeType, address _to) internal onlyOwner {
        if (_feeType == FeeType.FIAT) revert FiatBalanceNotWithdrawable();

        uint256 balance = getHostItBalance(_feeType); // {tok}
        if (balance == 0) revert InsufficientWithdrawBalance();
        delete marketplaceStorage().hostItBalance[_feeType];

        if (_feeType == FeeType.NATIVE) {
            SafeTransferLib.forceSafeTransferETH(_to, balance);
        } else {
            SafeTransferLib.safeTransfer(getFeeTokenAddress(_feeType), _to, balance);
        }
        emit HostItBalanceWithdrawn(_feeType, balance, _to);
    }

    /// @param _totalFee {tok}
    /// @param _to {addr}
    function _payWithToken(MarketplaceStorage storage _ms, FeeType _feeType, uint256 _totalFee, address _to) private {
        address caller = ContextLib.msgSender(); // {addr}

        address tokenAddress = getFeeTokenAddress(_ms, _feeType); // {addr}
        IERC20 token = IERC20(tokenAddress);
        if (!SafeTransferLib.trySafeTransferFrom(tokenAddress, caller, _to, _totalFee)) {
            // {tok} < {tok}
            if (token.balanceOf(caller) < _totalFee) {
                revert InsufficientBalance(tokenAddress, _feeType, _totalFee);
            }
            // {tok} < {tok}
            if (token.allowance(caller, address(this)) < _totalFee) {
                revert InsufficientAllowance(tokenAddress, _feeType, _totalFee);
            }
            revert PaymentFailed(_feeType, _totalFee);
        }
    }

    function _createErc6551Account(address _ticketAddress, uint256 _tokenId) internal {
        try IERC6551Registry(ERC6551_REGISTRY)
            .createAccount(ACCOUNT_V3_IMPLEMENTATION, "", block.chainid, _ticketAddress, _tokenId) returns (
            address account
        ) {
            if (account == address(0)) {
                revert CreateERC6551AccountFailed();
            }
        } catch {
            revert CreateERC6551AccountFailed();
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                        FIAT PAYMENT — INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Direct backend-call path. Only the configured `trustedBackend` may call.
    /// @param _ticketId {ticketId}
    /// @param _buyer {addr}
    /// @param _amount {fiat} smallest unit charged off-chain
    /// @param _paymentId backend-generated globally unique payment identifier
    /// @return tokenId_ {ticket}
    function mintFiatTicket(uint64 _ticketId, address _buyer, uint256 _amount, bytes32 _paymentId)
        internal
        returns (uint40 tokenId_)
    {
        _requireBackend();
        tokenId_ = _mintFiatTicket(_ticketId, _buyer, _amount, _paymentId);
    }

    /// @notice EIP-712 voucher redemption path. Anyone (typically the buyer) may submit a backend-signed voucher.
    function redeemFiatVoucher(FiatVoucher calldata _v, bytes calldata _signature) internal returns (uint40 tokenId_) {
        _verifyVoucher(_v, _signature);
        tokenId_ = _mintFiatTicket(_v.ticketId, _v.buyer, _v.amount, _v.paymentId);
    }

    /// @notice Backend-only batch direct mint. Atomic: any per-item revert rolls back the whole tx.
    function batchMintFiatTickets(
        uint64[] calldata _ticketIds,
        address[] calldata _buyers,
        uint256[] calldata _amounts,
        bytes32[] calldata _paymentIds
    ) internal returns (uint40[] memory tokenIds_) {
        _requireBackend();
        uint256 n = _ticketIds.length;
        if (n == 0 || n != _buyers.length || n != _amounts.length || n != _paymentIds.length) {
            revert BatchLengthMismatch();
        }
        tokenIds_ = new uint40[](n);
        for (uint256 i; i < n; ++i) {
            tokenIds_[i] = _mintFiatTicket(_ticketIds[i], _buyers[i], _amounts[i], _paymentIds[i]);
        }
    }

    /// @notice Batch voucher redemption. Anyone may submit. Each voucher verified independently. Atomic.
    function batchRedeemFiatVouchers(FiatVoucher[] calldata _vouchers, bytes[] calldata _signatures)
        internal
        returns (uint40[] memory tokenIds_)
    {
        uint256 n = _vouchers.length;
        if (n == 0 || n != _signatures.length) revert BatchLengthMismatch();
        tokenIds_ = new uint40[](n);
        for (uint256 i; i < n; ++i) {
            _verifyVoucher(_vouchers[i], _signatures[i]);
            tokenIds_[i] =
                _mintFiatTicket(_vouchers[i].ticketId, _vouchers[i].buyer, _vouchers[i].amount, _vouchers[i].paymentId);
        }
    }

    /// @notice Owner-only setter for the trusted backend address. `address(0)` disables both fiat paths.
    function setTrustedBackend(address _backend) internal onlyOwner {
        address prev = marketplaceStorage().trustedBackend;
        marketplaceStorage().trustedBackend = _backend;
        emit TrustedBackendUpdated(prev, _backend);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function setFeeTokenAddresses(FeeType[] calldata _feeTypes, address[] calldata _tokenAddresses) internal {
        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength == 0 || feeTypesLength != _tokenAddresses.length) {
            revert InvalidFeeConfig();
        }
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_tokenAddresses[i] == address(0)) revert TokenAddressZero();
            marketplaceStorage().feeTokenAddress[_feeTypes[i]] = _tokenAddresses[i];
        }
        emit TicketFeeAddressSet(_feeTypes, _tokenAddresses);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function feeEnabled(uint64 _ticketId, FeeType _feeType) internal view returns (bool) {
        return feeEnabled(marketplaceStorage(), _ticketId, _feeType);
    }

    function feeEnabled(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (bool)
    {
        return _ms.ticketFee[_ticketId][_feeType] > 0;
    }

    function getFeeTokenAddress(FeeType _feeType) internal view returns (address) {
        return getFeeTokenAddress(marketplaceStorage(), _feeType);
    }

    function getFeeTokenAddress(MarketplaceStorage storage _ms, FeeType _feeType)
        internal
        view
        returns (address tokenAddress_)
    {
        tokenAddress_ = _ms.feeTokenAddress[_feeType];
        if (tokenAddress_ == address(0)) revert TokenAddressZero();
    }

    /// @return {tok}
    function getTicketFee(uint64 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return getTicketFee(marketplaceStorage(), _ticketId, _feeType);
    }

    /// @return {tok}
    function getTicketFee(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256)
    {
        return _ms.ticketFee[_ticketId][_feeType];
    }

    /// @return ticketFee_ {tok}
    /// @return hostItFee_ {tok}
    /// @return totalFee_ {tok}
    function getFees(uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        return getFees(marketplaceStorage(), _ticketId, _feeType);
    }

    /// @return ticketFee_ {tok}
    /// @return hostItFee_ {tok}
    /// @return totalFee_ {tok}
    function getFees(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        ticketFee_ = getTicketFee(_ms, _ticketId, _feeType); // {tok}
        hostItFee_ = getHostItFee(ticketFee_); // {tok}
        totalFee_ = ticketFee_ + hostItFee_; // {tok} = {tok} + {tok}
    }

    /// @return {tok}
    function getTicketBalance(uint64 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return getTicketBalance(marketplaceStorage(), _ticketId, _feeType);
    }

    /// @return {tok}
    function getTicketBalance(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256)
    {
        return _ms.ticketBalance[_ticketId][_feeType];
    }

    /// @return {tok}
    function getHostItBalance(FeeType _feeType) internal view returns (uint256) {
        return getHostItBalance(marketplaceStorage(), _feeType);
    }

    /// @return {tok}
    function getHostItBalance(MarketplaceStorage storage _ms, FeeType _feeType) internal view returns (uint256) {
        return _ms.hostItBalance[_feeType];
    }

    /// @param _fee {tok}
    /// @return {tok}
    function getHostItFee(uint256 _fee) internal pure returns (uint256) {
        // {tok} = ({tok} * BPS{1}) / BPS{1}
        return ((_fee * HOSTIT_FEE_BPS) / FEE_BASIS_POINTS);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                          FIAT PAYMENT — VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getTrustedBackend() internal view returns (address) {
        return marketplaceStorage().trustedBackend;
    }

    function isFiatPaidToken(uint64 _ticketId, uint40 _tokenId) internal view returns (bool) {
        return marketplaceStorage().isFiatPaidToken[_ticketId][_tokenId];
    }

    function isFiatPaymentIdUsed(bytes32 _paymentId) internal view returns (bool) {
        return marketplaceStorage().usedFiatPaymentIds[_paymentId];
    }

    /// @return {fiat}
    function getTicketFiatRevenue(uint64 _ticketId) internal view returns (uint256) {
        return marketplaceStorage().ticketFiatRevenue[_ticketId];
    }

    function getFiatDomainSeparator() internal view returns (bytes32) {
        return _domainSeparator();
    }

    function hashFiatVoucher(FiatVoucher calldata _v) internal pure returns (bytes32) {
        return _structHash(_v);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                           PRIVATE HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Shared pre-mint validation for both crypto and fiat paths. Reads `ITicket.balanceOf` to fail fast
    ///      before any payment is moved.
    function _preMintChecks(uint64 _ticketId, address _buyer) private view returns (ExtraTicketData memory td_) {
        FactoryLib.checkTicketExists(_ticketId);
        td_ = FactoryLib.getExtraTicketData(_ticketId);
        uint48 time = SafeCastLib.toUint48(block.timestamp); // {s}
        if (td_.soldTickets == td_.maxTickets) revert TicketSoldOut(); // {ticket} == {ticket}
        if (time < td_.purchaseStartTime) revert PurchaseTimeNotReached(); // {s} < {s}
        if (time > td_.endTime) revert PurchaseTimeNotReached(); // {s} > {s}
        if (ITicket(td_.ticketAddress).balanceOf(_buyer) >= td_.maxTicketsPerUser) {
            revert MaxTicketsHeld(); // {ticket} >= {ticket}
        }
    }

    /// @dev Shared post-mint accounting for both crypto and fiat paths.
    function _finalizeMint(ExtraTicketData memory _td, address _buyer, FeeType _feeType, uint256 _totalFee)
        private
        returns (uint40 tokenId_)
    {
        tokenId_ = SafeCastLib.toUint40(ITicket(_td.ticketAddress).mint(_buyer)); // {ticket}
        ++FactoryLib.factoryStorage().ticketIdToData[_td.id].soldTickets; // {ticket}
        if (tokenId_ != FactoryLib.factoryStorage().ticketIdToData[_td.id].soldTickets) {
            revert TicketAccountingMismatch();
        }
        emit TicketMinted(_td.id, _feeType, _totalFee, tokenId_);
    }

    /// @dev Core fiat mint funnel used by all four entry points. No tokens moved; HostIt's fiat share is
    ///      reconciled entirely off-chain and is intentionally NOT accumulated in `hostItBalance[FIAT]`.
    function _mintFiatTicket(uint64 _ticketId, address _buyer, uint256 _amount, bytes32 _paymentId)
        private
        returns (uint40 tokenId_)
    {
        MarketplaceStorage storage ms = marketplaceStorage();
        if (_paymentId == bytes32(0)) revert InvalidPaymentId();
        if (ms.usedFiatPaymentIds[_paymentId]) revert PaymentIdAlreadyUsed(_paymentId);
        if (_amount == 0) revert ZeroFiatAmount();
        ms.usedFiatPaymentIds[_paymentId] = true;

        ExtraTicketData memory td = _preMintChecks(_ticketId, _buyer);
        if (td.isFree) revert TicketIsFree();

        tokenId_ = _finalizeMint(td, _buyer, FeeType.FIAT, _amount);
        ms.isFiatPaidToken[_ticketId][tokenId_] = true;
        ms.ticketFiatRevenue[_ticketId] += _amount; // {fiat} += {fiat}

        emit FiatTicketMinted(_ticketId, _buyer, tokenId_, _amount, _paymentId);
    }

    function _requireBackend() private view {
        address trusted = marketplaceStorage().trustedBackend;
        if (trusted == address(0) || msg.sender != trusted) revert UnauthorizedBackend();
    }

    function _verifyVoucher(FiatVoucher calldata _v, bytes calldata _signature) private view {
        if (block.timestamp > _v.expiresAt) revert VoucherExpired();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), _structHash(_v)));
        address signer = ECDSA.recover(digest, _signature);
        address trusted = marketplaceStorage().trustedBackend;
        if (trusted == address(0) || signer != trusted) revert InvalidVoucherSignature();
    }

    function _domainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, EIP712_NAME_HASH, EIP712_VERSION_HASH, block.chainid, address(this))
        );
    }

    function _structHash(FiatVoucher calldata _v) private pure returns (bytes32) {
        return
            keccak256(abi.encode(FIAT_VOUCHER_TYPEHASH, _v.ticketId, _v.buyer, _v.amount, _v.paymentId, _v.expiresAt));
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyMainTicketAdmin(uint64 _ticketId) {
        FactoryLib.checkMainTicketAdminRole(_ticketId);
        _;
    }

    modifier onlyOwner() {
        OwnableLib.checkOwner();
        _;
    }
}
