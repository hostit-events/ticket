// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ContextLib} from "@diamond/libraries/ContextLib.sol";
import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ACCOUNT_V3_IMPLEMENTATION, ERC6551_REGISTRY} from "@ticket-script/helpers/AddressesAndFees.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {ExtraTicketData, FactoryLib} from "@ticket/libs/FactoryLib.sol";
import {IERC6551Registry} from "erc6551/src/interfaces/IERC6551Registry.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

event TicketFeeSet(uint64 indexed ticketId, FeeType[] feeType, uint256[] fee); // ticketId:{ticketId}, fee:{tok}

event TicketRefunded(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event HostItFeeBpsSet(uint16 indexed hostItFeeBps); // hostItFeeBps:BPS{1}

event TicketFeeAddressSet(FeeType[] feeType, address[] token); // token:{addr}

event TicketMinted(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, uint40 tokenId); // fee:{tok}, tokenId:{ticket}

event TicketBalanceWithdrawn(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event HostItBalanceWithdrawn(FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

error ContractNotAllowed();
error PurchaseTimeNotReached();
error TicketSoldOut();
error MaxTicketsHeld();
error TokenAddressZero();
error InvalidFeeConfig();
error FeeAlreadySet();
error ZeroFee();
error TicketIsFree();
error FeeNotEnabled(uint64, FeeType);
error TicketNotApproved(uint256);
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
error TicketUnpauseFailed();
error CreateERC6551AccountFailed();
error InvalidHostItFeeBps();
error TicketTransferFailed();

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.marketplace.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant MARKETPLACE_STORAGE_LOCATION = 0x3f09c55b469305b27ecae2a46b3f364669f622316549d801837d9eeba9778d00;

/// @title FeeType
/// @notice Enum for fee types
enum FeeType {
    NONE,
    ETH,
    WETH,
    USDT,
    USDC,
    USDT0,
    EURC,
    GHO,
    LINK,
    LSK
}

/// @title MarketplaceStorage
/// @notice Storage structure for managing marketplace data
/// @custom:storage-location erc7201:host.it.ticket.marketplace.storage
struct MarketplaceStorage {
    mapping(uint64 => mapping(FeeType => uint256)) ticketFee; // {ticketId} => FeeType => {tok}
    mapping(uint64 => mapping(FeeType => uint256)) ticketBalance; // {ticketId} => FeeType => {tok}
    mapping(FeeType => address) feeTokenAddress; // FeeType => {addr}
    mapping(FeeType => uint256) hostItBalance; // FeeType => {tok}
}

library MarketplaceLib {
    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    uint256 internal constant REFUND_PERIOD = 3 days; // {s}

    uint256 private constant HOSTIT_FEE_BPS = 300; // BPS{1} 3% fee in basis points
    uint256 private constant FEE_BASIS_POINTS = 10_000; // BPS{1} 10,000 basis points

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
        FactoryLib.checkTicketExists(_ticketId);

        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);

        {
            uint48 time = SafeCastLib.toUint48(block.timestamp); // {s}
            // {s} < {s}
            if (time < ticketData.purchaseStartTime) {
                revert PurchaseTimeNotReached();
            }
            if (time > ticketData.endTime) revert PurchaseTimeNotReached(); // {s} > {s}
            if (ticketData.soldTickets == ticketData.maxTickets) {
                // {ticket} == {ticket}
                revert TicketSoldOut();
            }
        }

        ITicket ticket = ITicket(ticketData.ticketAddress);
        // {ticket} > {ticket}
        if (ticket.balanceOf(_buyer) > ticketData.maxTicketsPerUser) {
            revert MaxTicketsHeld();
        }

        MarketplaceStorage storage ms = marketplaceStorage();
        // {tok}, {tok}, {tok}
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = getFees(ms, _ticketId, _feeType);
        if (!ticketData.isFree) {
            if (!_feeEnabled(ms, _ticketId, _feeType)) revert FeeNotEnabled(_ticketId, _feeType);

            if (ticketData.isRefundable) {
                if (_feeType == FeeType.ETH) {
                    // {tok} < {tok}
                    if (msg.value < totalFee) {
                        revert InsufficientPayment(_feeType, totalFee);
                    }
                } else {
                    _payWithToken(ms, _feeType, totalFee, address(this));
                }
                ms.ticketBalance[_ticketId][_feeType] += fee; // {tok} += {tok}
            } else {
                if (_feeType == FeeType.ETH) {
                    // {tok} < {tok}
                    if (msg.value < totalFee) {
                        revert InsufficientPayment(_feeType, totalFee);
                    }
                    SafeTransferLib.forceSafeTransferETH(ticketData.ticketAdmin, fee);
                } else {
                    _payWithToken(ms, _feeType, fee, ticketData.ticketAdmin);
                    _payWithToken(ms, _feeType, hostItFee, address(this));
                }
            }
            ms.hostItBalance[_feeType] += hostItFee; // {tok} += {tok}
        }

        tokenId_ = SafeCastLib.toUint40(ticket.mint(_buyer)); // {ticket}
        ++FactoryLib.factoryStorage().ticketIdToData[_ticketId].soldTickets; // {ticket}
        // {ticket} != {ticket}
        if (tokenId_ != FactoryLib.factoryStorage().ticketIdToData[_ticketId].soldTickets) {
            revert TicketAccountingMismatch();
        }

        emit TicketMinted(_ticketId, _feeType, totalFee, tokenId_);
    }

    /// @param _ticketId {ticketId}
    /// @param _fees {tok} per-ticket price in each fee token
    function setTicketFees(uint64 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        FactoryLib.checkTicketExists(_ticketId);

        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength != _fees.length && feeTypesLength > 0) {
            revert InvalidFeeConfig();
        }
        FactoryLib.factoryStorage().ticketIdToData[_ticketId].isFree = false;

        MarketplaceStorage storage ms = marketplaceStorage();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_fees[i] == 0) revert ZeroFee();

            ms.ticketFee[_ticketId][_feeTypes[i]] = _fees[i]; // {tok}
        }

        emit TicketFeeSet(_ticketId, _feeTypes, _fees);
    }

    /// @param _ticketId {ticketId}
    /// @param _tokenId {ticket}
    /// @param _to {addr}
    function claimRefund(uint64 _ticketId, FeeType _feeType, uint256 _tokenId, address _to) internal {
        FactoryLib.checkTicketExists(_ticketId);

        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);

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
        marketplaceStorage().ticketBalance[_ticketId][_feeType] -= ticketFee; // {tok} -= {tok}

        try ticket.safeTransferFrom(caller, ticketData.ticketAdmin, _tokenId) {}
        catch {
            revert TicketTransferFailed();
        }

        if (_feeType == FeeType.ETH) {
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
        FactoryLib.checkTicketExists(_ticketId);
        _checkIfContract(_to);

        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);

        if (ticketData.isRefundable) {
            // {s} < {s} + {s}
            if (block.timestamp < ticketData.endTime + REFUND_PERIOD) {
                revert WithdrawPeriodNotReached();
            }
        }

        uint256 balance = getTicketBalance(_ticketId, _feeType); // {tok}
        if (balance == 0) revert InsufficientWithdrawBalance();
        delete marketplaceStorage().ticketBalance[_ticketId][_feeType];

        if (_feeType == FeeType.ETH) {
            SafeTransferLib.safeTransferETH(_to, balance);
        } else {
            SafeTransferLib.safeTransfer(getFeeTokenAddress(_feeType), _to, balance);
        }

        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (ticket.paused()) {
            try ticket.unpause() {}
            catch {
                revert TicketUnpauseFailed();
            }
        }

        emit TicketBalanceWithdrawn(_ticketId, _feeType, balance, _to);
    }

    /// @param _to {addr}
    function withdrawHostItBalance(FeeType _feeType, address _to) internal onlyOwner {
        _checkIfContract(_to);

        uint256 balance = getHostItBalance(_feeType); // {tok}
        if (balance == 0) revert InsufficientWithdrawBalance();
        delete marketplaceStorage().hostItBalance[_feeType];

        if (_feeType == FeeType.ETH) {
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

        address tokenAddress = _getFeeTokenAddress(_ms, _feeType); // {addr}
        IERC20 token = IERC20(tokenAddress);
        // {tok} < {tok}
        if (token.balanceOf(caller) < _totalFee) {
            revert InsufficientBalance(tokenAddress, _feeType, _totalFee);
        }
        // {tok} < {tok}
        if (token.allowance(caller, address(this)) < _totalFee) {
            revert InsufficientAllowance(tokenAddress, _feeType, _totalFee);
        }
        if (!SafeTransferLib.trySafeTransferFrom(tokenAddress, caller, _to, _totalFee)) {
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
    //                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _setFeeTokenAddresses(FeeType[] calldata _feeTypes, address[] calldata _tokenAddresses) internal {
        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength != _tokenAddresses.length && feeTypesLength > 0) {
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
        return _feeEnabled(marketplaceStorage(), _ticketId, _feeType);
    }

    function _feeEnabled(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (bool)
    {
        return _ms.ticketFee[_ticketId][_feeType] > 0;
    }

    function getFeeTokenAddress(FeeType _feeType) internal view returns (address) {
        return _getFeeTokenAddress(marketplaceStorage(), _feeType);
    }

    function _getFeeTokenAddress(MarketplaceStorage storage _ms, FeeType _feeType)
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

    function _checkIfContract(address _address) private view {
        if (_address.code.length > 0) revert ContractNotAllowed();
    }

    /// @param _fee {tok}
    /// @return {tok}
    function getHostItFee(uint256 _fee) internal pure returns (uint256) {
        // {tok} = ({tok} * BPS{1}) / BPS{1}
        return ((_fee * HOSTIT_FEE_BPS) / FEE_BASIS_POINTS);
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
