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

    uint256 constant REFUND_PERIOD = 3 days;

    function _marketplaceStorage() internal pure returns (MarketplaceStorage storage ms_) {
        assembly {
            ms_.slot := MARKETPLACE_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _mintTicket(uint56 _ticketId, FeeType _feeType) internal {
        _ticketId._checkTicketExists();

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        uint40 time = uint40(block.timestamp);
        if (time < ticketData.purchaseStartTime) revert PurchaseTimeNotReached();
        if (time > ticketData.endTime) revert PurchaseTimeNotReached();
        if (ticketData.soldTickets == ticketData.maxTickets) revert TicketSoldOut();

        address buyer = LibContext._msgSender();
        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (ticket.balanceOf(buyer) > 1) revert MaxTicketsHeld();

        uint256 fee = _getTicketFee(_ticketId, _feeType);
        if (!ticketData.isFree) {
            if (!_getFeeEnabled(_ticketId, _feeType)) revert FeeNotEnabled();

            uint256 hostItFee = _calculateHostItFee(fee);
            uint256 totalFee = fee + hostItFee;

            if (_feeType == FeeType.ETH) {
                address(this).safeTransferETH(totalFee);
            } else {
                IERC20 token = IERC20(_getFeeTokenAddress(_feeType));
                if (token.balanceOf(buyer) < totalFee) revert InsufficientBalance(address(token), _feeType, totalFee);
                if (token.allowance(buyer, address(this)) < totalFee) {
                    revert InsufficientAllowance(address(token), _feeType, totalFee);
                }
                token.safeTransferFrom(buyer, address(this), totalFee);
            }

            MarketplaceStorage storage ms = _marketplaceStorage();
            ms.ticketBalance[_ticketId][_feeType] += fee;
            ms.hostItBalance[_feeType] += fee;
        }

        uint40 tokenId = uint40(ticket.mint(buyer));
        ++LibFactory._factoryStorage().ticketIdToData[_ticketId].soldTickets;
        emit TicketMinted(_ticketId, _feeType, fee, tokenId);
    }

    function _setTicketFees(uint56 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        _ticketId._checkTicketExists();

        if (_ticketId._isTicketFree()) revert TicketIsFree();

        uint256 feeTypesLength = _feeTypes.length;
        if (feeTypesLength != _fees.length && feeTypesLength > 0) revert InvalidFeeConfig();

        MarketplaceStorage storage ms = _marketplaceStorage();
        for (uint256 i; i < feeTypesLength; ++i) {
            if (_getFeeEnabled(_ticketId, _feeTypes[i])) revert FeeAlreadySet();
            if (_fees[i] == 0) revert ZeroFee();

            ms.feeEnabled[_ticketId][_feeTypes[i]] = true;
            ms.ticketFee[_ticketId][_feeTypes[i]] = _fees[i];

            emit TicketFeeSet(_ticketId, _feeTypes[i], _fees[i]);
        }
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

    // TODO
    // function _requestRefund(uint56 _ticketId, FeeType _feeType, uint256 _tokenId) internal {
    //     _ticketId._checkTicketExists();
    // }

    // TODO
    // function _fulfillRefund(uint56 _ticketId, FeeType _feeType) internal {}

    function _withdrawTicketBalance(uint56 _ticketId, FeeType _feeType, address _to)
        internal
        onlyMainTicketAdmin(_ticketId)
        returns (address vault_)
    {
        _ticketId._checkTicketExists();

        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        if (block.timestamp > ticketData.endTime + REFUND_PERIOD) revert WithdrawPeriodNotReached();
        uint256 balance = _getTicketBalance(_ticketId, _feeType);
        if (balance == 0) revert InsufficientWithdrawBalance();
        _marketplaceStorage().ticketBalance[_ticketId][_feeType] = 0;

        if (_feeType == FeeType.ETH) {
            vault_ = _to.safeMoveETH(balance);
        } else {
            IERC20(_getFeeTokenAddress(_feeType)).safeTransfer(_to, balance);
        }
    }

    function _withdrawHostItBalance(FeeType _feeType, address _to) internal onlyOwner returns (address vault_) {
        uint256 balance = _getHostItBalance(_feeType);
        if (balance == 0) revert InsufficientWithdrawBalance();
        _marketplaceStorage().hostItBalance[_feeType] = 0;

        if (_feeType == FeeType.ETH) {
            vault_ = _to.safeMoveETH(balance);
        } else {
            IERC20(_getFeeTokenAddress(_feeType)).safeTransfer(_to, balance);
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getFeeEnabled(uint56 _ticketId, FeeType _feeType) internal view returns (bool) {
        return _marketplaceStorage().feeEnabled[_ticketId][_feeType];
    }

    function _getFeeTokenAddress(FeeType _feeType) internal view returns (address tokenAddress_) {
        tokenAddress_ = _marketplaceStorage().feeTokenAddress[_feeType];
        if (tokenAddress_ == address(0)) revert TokenAddressZero();
    }

    function _getTicketFee(uint56 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _marketplaceStorage().ticketFee[_ticketId][_feeType];
    }

    function _getTicketBalance(uint56 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _marketplaceStorage().ticketBalance[_ticketId][_feeType];
    }

    function _getHostItBalance(FeeType _feeType) internal view returns (uint256) {
        return _marketplaceStorage().hostItBalance[_feeType];
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _calculateHostItFee(uint256 _fee) internal pure returns (uint256) {
        return (_fee * 300) / 10_000; // 3% fee
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
