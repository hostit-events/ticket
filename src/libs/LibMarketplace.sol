// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {LibContext} from "@ticket/libs/LibContext.sol";
import {LibFactory} from "@ticket/libs/LibFactory.sol";
import {ExtraTicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType, MarketplaceStorage, MARKETPLACE_STORAGE_LOCATION} from "@ticket-storage/MarketplaceStorage.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/MarketplaceLogs.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-errors/MarketplaceErrors.sol";

library LibMarketplace {
    using LibFactory for uint56;
    using SafeTransferLib for address;
    using SafeERC20 for IERC20;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    uint256 private constant MAX_TICKETS_PER_HOLDER = 0;
    uint256 internal constant REFUND_PERIOD = 3 days;

    function _marketplaceStorage() internal pure returns (MarketplaceStorage storage ms_) {
        assembly {
            ms_.slot := MARKETPLACE_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _mintTicket(uint56 _ticketId, FeeType _feeType, address _buyer) internal returns (uint40 tokenId_) {
        _ticketId._checkTicketExists();

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        uint40 time = uint40(block.timestamp);
        if (time < ticketData.purchaseStartTime) revert PurchaseTimeNotReached();
        if (time > ticketData.endTime) revert PurchaseTimeNotReached();
        if (ticketData.soldTickets == ticketData.maxTickets) revert TicketSoldOut();

        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (ticket.balanceOf(_buyer) > MAX_TICKETS_PER_HOLDER) revert MaxTicketsHeld();

        (uint256 fee, uint256 hostItFee, uint256 totalFee) = _getFees(_ticketId, _feeType);
        if (!ticketData.isFree) {
            if (!_isFeeEnabled(_ticketId, _feeType)) revert FeeNotEnabled();

            if (_feeType == FeeType.ETH) {
                if (msg.value != totalFee) revert InsufficientBalance(address(0), _feeType, totalFee);
            } else {
                _payWithToken(_feeType, totalFee);
            }

            MarketplaceStorage storage ms = _marketplaceStorage();
            ms.ticketBalance[_ticketId][_feeType] += fee;
            ms.hostItBalance[_feeType] += hostItFee;
        }

        tokenId_ = uint40(ticket.mint(_buyer));
        ++LibFactory._factoryStorage().ticketIdToData[_ticketId].soldTickets;
        if (tokenId_ != LibFactory._factoryStorage().ticketIdToData[_ticketId].soldTickets) {
            revert FatalErrorTicketMismatch();
        }
        emit TicketMinted(_ticketId, _feeType, totalFee, tokenId_);
    }

    function _setTicketFees(uint56 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        _ticketId._checkTicketExists();

        LibFactory._factoryStorage().ticketIdToData[_ticketId].isFree = false;
        if (_ticketId._isTicketFree()) revert TicketIsFree();

        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength != _fees.length && feeTypesLength > 0) revert InvalidFeeConfig();

        MarketplaceStorage storage ms = _marketplaceStorage();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_isFeeEnabled(_ticketId, _feeTypes[i])) revert FeeAlreadySet();
            if (_fees[i] == 0) revert ZeroFee();

            ms.feeEnabled[_ticketId][_feeTypes[i]] = true;
            ms.ticketFee[_ticketId][_feeTypes[i]] = _fees[i];

            emit TicketFeeSet(_ticketId, _feeTypes[i], _fees[i]);
        }
    }

    // TODO
    // function _requestRefund(uint56 _ticketId, FeeType _feeType, uint256 _tokenId) internal {
    //     _ticketId._checkTicketExists();
    // }

    // TODO
    // function _fulfillRefund(uint56 _ticketId, FeeType _feeType) internal onlyRoleOrOwner {}

    function _withdrawTicketBalance(uint56 _ticketId, FeeType _feeType, address _to)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        _ticketId._checkTicketExists();
        _checkIfContract(_to);

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        if (block.timestamp < ticketData.endTime + REFUND_PERIOD) revert WithdrawPeriodNotReached();
        uint256 balance = _getTicketBalance(_ticketId, _feeType);
        if (balance == 0) revert InsufficientWithdrawBalance();
        _marketplaceStorage().ticketBalance[_ticketId][_feeType] = 0;

        if (_feeType == FeeType.ETH) {
            _to.safeTransferETH(balance);
        } else {
            IERC20(_getFeeTokenAddress(_feeType)).safeTransfer(_to, balance);
        }
        emit TicketBalanceWithdrawn(_ticketId, _feeType, balance, _to);
    }

    function _withdrawHostItBalance(FeeType _feeType, address _to) internal onlyOwner {
        _checkIfContract(_to);

        uint256 balance = _getHostItBalance(_feeType);
        if (balance == 0) revert InsufficientWithdrawBalance();
        _marketplaceStorage().hostItBalance[_feeType] = 0;

        if (_feeType == FeeType.ETH) {
            _to.safeTransferETH(balance);
        } else {
            IERC20(_getFeeTokenAddress(_feeType)).safeTransfer(_to, balance);
        }
        emit HostItBalanceWithdrawn(_feeType, balance, _to);
    }

    function _setFeeTokenAddresses(FeeType[] calldata _feeTypes, address[] calldata _tokenAddresses) internal {
        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength != _tokenAddresses.length && feeTypesLength > 0) revert InvalidFeeConfig();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_tokenAddresses[i] == address(0)) revert TokenAddressZero();
            _marketplaceStorage().feeTokenAddress[_feeTypes[i]] = _tokenAddresses[i];
            emit TicketFeeAddressSet(_feeTypes[i], _tokenAddresses[i]);
        }
    }

    function _payWithToken(FeeType _feeType, uint256 _totalFee) internal {
        address buyer = LibContext._msgSender();
        IERC20 token = IERC20(_getFeeTokenAddress(_feeType));
        if (token.balanceOf(buyer) < _totalFee) revert InsufficientBalance(address(token), _feeType, _totalFee);
        if (token.allowance(buyer, address(this)) < _totalFee) {
            revert InsufficientAllowance(address(token), _feeType, _totalFee);
        }
        if (!token.trySafeTransferFrom(buyer, address(this), _totalFee)) {
            revert TicketPurchaseFailed(_feeType, _totalFee);
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _isFeeEnabled(uint56 _ticketId, FeeType _feeType) internal view returns (bool) {
        return _marketplaceStorage().feeEnabled[_ticketId][_feeType];
    }

    function _getFeeTokenAddress(FeeType _feeType) internal view returns (address tokenAddress_) {
        tokenAddress_ = _marketplaceStorage().feeTokenAddress[_feeType];
        if (tokenAddress_ == address(0)) revert TokenAddressZero();
    }

    function _getTicketFee(uint56 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _marketplaceStorage().ticketFee[_ticketId][_feeType];
    }

    function _getFees(uint56 _ticketId, FeeType _feeType)
        internal
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        ticketFee_ = _getTicketFee(_ticketId, _feeType);
        hostItFee_ = _calculateHostItFee(ticketFee_);
        totalFee_ = ticketFee_ + hostItFee_;
    }

    function _getTicketBalance(uint56 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _marketplaceStorage().ticketBalance[_ticketId][_feeType];
    }

    function _getHostItBalance(FeeType _feeType) internal view returns (uint256) {
        return _marketplaceStorage().hostItBalance[_feeType];
    }

    function _checkIfContract(address _address) internal view {
        if (_address.code.length > 0) revert ContractNotAllowed();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _calculateHostItFee(uint256 _fee) internal pure returns (uint256) {
        return (_fee * 3_000 / 100_000); // 3% fee
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyMainTicketAdmin(uint56 _ticketId) {
        LibFactory._checkMainTicketAdminRole(_ticketId);
        _;
    }

    modifier onlyOwner() {
        LibOwnableRoles._checkOwner();
        _;
    }
}
