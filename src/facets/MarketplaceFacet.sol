// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IMarketplace} from "@ticket/interfaces/IMarketplace.sol";
import {LibMarketplace} from "@ticket/libs/LibMarketplace.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

contract MarketplaceFacet is IMarketplace {
    using LibMarketplace for *;

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function mintTicket(uint56 _ticketId, FeeType _feeType, address _buyer) external payable returns (uint40) {
        return _ticketId._mintTicket(_feeType, _buyer);
    }

    function setTicketFees(uint56 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees) external {
        _ticketId._setTicketFees(_feeTypes, _fees);
    }

    function withdrawTicketBalance(uint56 _ticketId, FeeType _feeType, address _to) external {
        _ticketId._withdrawTicketBalance(_feeType, _to);
    }

    function withdrawHostItBalance(FeeType _feeType, address _to) external {
        _feeType._withdrawHostItBalance(_to);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isFeeEnabled(uint56 _ticketId, FeeType _feeType) external view returns (bool) {
        return _ticketId._isFeeEnabled(_feeType);
    }

    function getFeeTokenAddress(FeeType _feeType) external view returns (address) {
        return _feeType._getFeeTokenAddress();
    }

    function getTicketFee(uint56 _ticketId, FeeType _feeType) external view returns (uint256) {
        return _ticketId._getTicketFee(_feeType);
    }

    function getAllFees(uint56 _ticketId, FeeType _feeType)
        external
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        return _ticketId._getFees(_feeType);
    }

    function getTicketBalance(uint56 _ticketId, FeeType _feeType) external view returns (uint256) {
        return _ticketId._getTicketBalance(_feeType);
    }

    function getHostItBalance(FeeType _feeType) external view returns (uint256) {
        return _feeType._getHostItBalance();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function calculateHostItFee(uint256 _fee) external pure returns (uint256) {
        return _fee._calculateHostItFee();
    }

    function getRefundPeriod() external pure returns (uint256) {
        return LibMarketplace.REFUND_PERIOD;
    }
}
