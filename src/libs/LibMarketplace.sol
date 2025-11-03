// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ACCOUNT_V3_IMPLEMENTATION, ERC6551_REGISTRY} from "@ticket-script/helpers/LibAddressesAndFees.sol";
import {ExtraTicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType, MARKETPLACE_STORAGE_LOCATION, MarketplaceStorage} from "@ticket-storage/MarketplaceStorage.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {LibContext} from "@ticket/libs/LibContext.sol";
import {LibFactory} from "@ticket/libs/LibFactory.sol";
import {IERC6551Registry} from "erc6551/src/interfaces/IERC6551Registry.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/MarketplaceLogs.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-errors/MarketplaceErrors.sol";

library LibMarketplace {
    using LibFactory for uint64;
    using SafeCastLib for uint256;
    using SafeTransferLib for address;
    using SafeTransferLib for IERC20;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    uint256 internal constant REFUND_PERIOD = 3 days;

    uint256 private constant HOSTIT_FEE_BPS = 300; // 3% fee in basis points
    uint256 private constant FEE_BASIS_POINTS = 10_000; // 10,000 basis points

    function _marketplaceStorage() internal pure returns (MarketplaceStorage storage ms_) {
        assembly {
            ms_.slot := MARKETPLACE_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _mintTicket(uint64 _ticketId, FeeType _feeType, address _buyer) internal returns (uint40 tokenId_) {
        _ticketId._checkTicketExists();

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        uint48 time = block.timestamp.toUint48();
        if (time < ticketData.purchaseStartTime) revert PurchaseTimeNotReached();
        if (time > ticketData.endTime) revert PurchaseTimeNotReached();
        if (ticketData.soldTickets == ticketData.maxTickets) revert TicketSoldOut();

        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (ticket.balanceOf(_buyer) > ticketData.maxTicketsPerUser) revert MaxTicketsHeld();

        MarketplaceStorage storage ms = _marketplaceStorage();
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = _getFees(ms, _ticketId, _feeType);
        if (!ticketData.isFree) {
            if (!_isFeeEnabled(ms, _ticketId, _feeType)) revert FeeNotEnabled();

            if (_feeType == FeeType.ETH) {
                if (msg.value < totalFee) revert InsufficientBalance(address(0), _feeType, totalFee);
            } else {
                _payWithToken(ms, _feeType, totalFee);
            }

            ms.ticketBalance[_ticketId][_feeType] += fee;
            ms.hostItBalance[_feeType] += hostItFee;
        }

        tokenId_ = ticket.mint(_buyer).toUint40();
        ++LibFactory._factoryStorage().ticketIdToData[_ticketId].soldTickets;
        if (tokenId_ != LibFactory._factoryStorage().ticketIdToData[_ticketId].soldTickets) {
            revert TicketAccountingMismatch();
        }

        emit TicketMinted(_ticketId, _feeType, totalFee, tokenId_);
    }

    function _setTicketFees(uint64 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        _ticketId._checkTicketExists();

        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength != _fees.length && feeTypesLength > 0) revert InvalidFeeConfig();
        LibFactory._factoryStorage().ticketIdToData[_ticketId].isFree = false;

        MarketplaceStorage storage ms = _marketplaceStorage();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_isFeeEnabled(ms, _ticketId, _feeTypes[i])) revert FeeAlreadySet();
            if (_fees[i] == 0) revert ZeroFee();

            ms.feeEnabled[_ticketId][_feeTypes[i]] = true;
            ms.ticketFee[_ticketId][_feeTypes[i]] = _fees[i];
        }

        emit TicketFeeSet(_ticketId, _feeTypes, _fees);
    }

    function _claimRefund(uint64 _ticketId, FeeType _feeType, uint256 _tokenId, address _to) internal {
        _ticketId._checkTicketExists();

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        if (!ticketData.isRefundable) revert RefundNotEnabled();

        uint48 time = block.timestamp.toUint48();
        if (time < ticketData.endTime) revert RefundPeriodNotReached();
        if (time > ticketData.endTime + REFUND_PERIOD) revert RefundPeriodExpired();

        address caller = LibContext._msgSender();
        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (caller != ticket.ownerOf(_tokenId)) revert TicketNotOwned(_tokenId);

        uint256 ticketFee = _getTicketFee(_ticketId, _feeType);
        _marketplaceStorage().ticketBalance[_ticketId][_feeType] -= ticketFee;

        try ticket.safeTransferFrom(caller, ticketData.ticketAdmin, _tokenId) {}
        catch {
            revert TicketTransferFailed();
        }

        if (_feeType == FeeType.ETH) {
            _to.safeTransferETH(ticketFee);
        } else {
            _getFeeTokenAddress(_feeType).safeTransfer(_to, ticketFee);
        }

        emit TicketRefunded(_ticketId, _feeType, ticketFee, _to);
    }

    function _withdrawTicketBalance(uint64 _ticketId, FeeType _feeType, address _to)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        _ticketId._checkTicketExists();
        _checkIfContract(_to);

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        if (ticketData.isRefundable) {
            if (block.timestamp < ticketData.endTime + REFUND_PERIOD) revert WithdrawPeriodNotReached();
        }

        uint256 balance = _getTicketBalance(_ticketId, _feeType);
        if (balance == 0) revert InsufficientWithdrawBalance();
        delete _marketplaceStorage().ticketBalance[_ticketId][_feeType];

        if (_feeType == FeeType.ETH) {
            _to.safeTransferETH(balance);
        } else {
            _getFeeTokenAddress(_feeType).safeTransfer(_to, balance);
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

    function _withdrawHostItBalance(FeeType _feeType, address _to) internal onlyOwner {
        _checkIfContract(_to);

        uint256 balance = _getHostItBalance(_feeType);
        if (balance == 0) revert InsufficientWithdrawBalance();
        delete _marketplaceStorage().hostItBalance[_feeType];

        if (_feeType == FeeType.ETH) {
            _to.safeTransferETH(balance);
        } else {
            _getFeeTokenAddress(_feeType).safeTransfer(_to, balance);
        }
        emit HostItBalanceWithdrawn(_feeType, balance, _to);
    }

    function _payWithToken(MarketplaceStorage storage _ms, FeeType _feeType, uint256 _totalFee) internal {
        address caller = LibContext._msgSender();

        address tokenAddress = _getFeeTokenAddress(_ms, _feeType);
        IERC20 token = IERC20(tokenAddress);
        if (token.balanceOf(caller) < _totalFee) revert InsufficientBalance(tokenAddress, _feeType, _totalFee);
        if (token.allowance(caller, address(this)) < _totalFee) {
            revert InsufficientAllowance(tokenAddress, _feeType, _totalFee);
        }
        if (!tokenAddress.trySafeTransferFrom(caller, address(this), _totalFee)) {
            revert TicketPurchaseFailed(_feeType, _totalFee);
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
        if (feeTypesLength != _tokenAddresses.length && feeTypesLength > 0) revert InvalidFeeConfig();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_tokenAddresses[i] == address(0)) revert TokenAddressZero();
            _marketplaceStorage().feeTokenAddress[_feeTypes[i]] = _tokenAddresses[i];
        }
        emit TicketFeeAddressSet(_feeTypes, _tokenAddresses);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _isFeeEnabled(uint64 _ticketId, FeeType _feeType) internal view returns (bool) {
        return _isFeeEnabled(_marketplaceStorage(), _ticketId, _feeType);
    }

    function _isFeeEnabled(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (bool)
    {
        return _ms.feeEnabled[_ticketId][_feeType];
    }

    function _getFeeTokenAddress(FeeType _feeType) internal view returns (address) {
        return _getFeeTokenAddress(_marketplaceStorage(), _feeType);
    }

    function _getFeeTokenAddress(MarketplaceStorage storage _ms, FeeType _feeType)
        internal
        view
        returns (address tokenAddress_)
    {
        tokenAddress_ = _ms.feeTokenAddress[_feeType];
        if (tokenAddress_ == address(0)) revert TokenAddressZero();
    }

    function _getTicketFee(uint64 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _getTicketFee(_marketplaceStorage(), _ticketId, _feeType);
    }

    function _getTicketFee(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256)
    {
        return _ms.ticketFee[_ticketId][_feeType];
    }

    function _getFees(uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        ticketFee_ = _getTicketFee(_ticketId, _feeType);
        hostItFee_ = _getHostItFee(ticketFee_);
        totalFee_ = ticketFee_ + hostItFee_;
    }

    function _getFees(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        ticketFee_ = _getTicketFee(_ms, _ticketId, _feeType);
        hostItFee_ = _getHostItFee(ticketFee_);
        totalFee_ = ticketFee_ + hostItFee_;
    }

    function _getTicketBalance(uint64 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _getTicketBalance(_marketplaceStorage(), _ticketId, _feeType);
    }

    function _getTicketBalance(MarketplaceStorage storage _ms, uint64 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256)
    {
        return _ms.ticketBalance[_ticketId][_feeType];
    }

    function _getHostItBalance(FeeType _feeType) internal view returns (uint256) {
        return _getHostItBalance(_marketplaceStorage(), _feeType);
    }

    function _getHostItBalance(MarketplaceStorage storage _ms, FeeType _feeType) internal view returns (uint256) {
        return _ms.hostItBalance[_feeType];
    }

    function _checkIfContract(address _address) internal view {
        if (_address.code.length > 0) revert ContractNotAllowed();
    }

    function _getHostItFee(uint256 _fee) internal pure returns (uint256) {
        return ((_fee * HOSTIT_FEE_BPS) / FEE_BASIS_POINTS);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyMainTicketAdmin(uint64 _ticketId) {
        LibFactory._checkMainTicketAdminRole(_ticketId);
        _;
    }

    modifier onlyOwner() {
        LibOwnableRoles._checkOwner();
        _;
    }
}
