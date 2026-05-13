// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IMarketplace} from "@ticket/interfaces/IMarketplace.sol";
import {FeeType} from "@ticket/libs/MarketplaceLib.sol";
import {MarketplaceLib} from "@ticket/libs/MarketplaceLib.sol";

contract MarketplaceFacet is IMarketplace {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @inheritdoc IMarketplace
    function mintTicket(uint64 _ticketId, FeeType _feeType, address _buyer) external payable returns (uint40) {
        return MarketplaceLib.mintTicket(_ticketId, _feeType, _buyer); // {ticket}
    }

    function updateTicketFees(uint64 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees) external {
        MarketplaceLib.updateTicketFees(_ticketId, _feeTypes, _fees);
    }

    function claimRefund(uint64 _ticketId, FeeType _feeType, uint256 _tokenId, address _to) external {
        MarketplaceLib.claimRefund(_ticketId, _feeType, _tokenId, _to);
    }

    function withdrawTicketBalance(uint64 _ticketId, FeeType _feeType, address _to) external {
        MarketplaceLib.withdrawTicketBalance(_ticketId, _feeType, _to);
    }

    function withdrawHostItBalance(FeeType _feeType, address _to) external {
        MarketplaceLib.withdrawHostItBalance(_feeType, _to);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    // @return {1}
    function feeEnabled(uint64 _ticketId, FeeType _feeType) external view returns (bool) {
        return MarketplaceLib.feeEnabled(_ticketId, _feeType);
    }

    // @return {addr}
    function getFeeTokenAddress(FeeType _feeType) external view returns (address) {
        return MarketplaceLib.getFeeTokenAddress(_feeType);
    }

    // @return {tok}
    function getTicketFee(uint64 _ticketId, FeeType _feeType) external view returns (uint256) {
        return MarketplaceLib.getTicketFee(_ticketId, _feeType);
    }

    // @return ticketFee_ {tok}, hostItFee_ {tok}, totalFee_ {tok}
    function getAllFees(uint64 _ticketId, FeeType _feeType)
        external
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        return MarketplaceLib.getFees(_ticketId, _feeType);
    }

    // @return {tok}
    function getTicketBalance(uint64 _ticketId, FeeType _feeType) external view returns (uint256) {
        return MarketplaceLib.getTicketBalance(_ticketId, _feeType);
    }

    // @return {tok}
    function getHostItBalance(FeeType _feeType) external view returns (uint256) {
        return MarketplaceLib.getHostItBalance(_feeType);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    // @param _fee {tok} @return {tok}
    function getHostItFee(uint256 _fee) external pure returns (uint256) {
        return MarketplaceLib.getHostItFee(_fee);
    }

    // @return {s}
    function getRefundPeriod() external pure returns (uint256) {
        return MarketplaceLib.REFUND_PERIOD;
    }
}
