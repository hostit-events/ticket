// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

interface IMarketplace {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function mintTicket(uint64 ticketId, FeeType feeType, address buyer) external payable returns (uint40);

    function setTicketFees(uint64 ticketId, FeeType[] calldata feeTypes, uint256[] calldata fees) external;

    function claimRefund(uint64 ticketId, FeeType feeType, uint256 tokenId, address to) external;

    function withdrawTicketBalance(uint64 ticketId, FeeType feeType, address to) external;

    function withdrawHostItBalance(FeeType feeType, address to) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isFeeEnabled(uint64 ticketId, FeeType feeType) external view returns (bool);

    function getFeeTokenAddress(FeeType feeType) external view returns (address);

    function getTicketFee(uint64 ticketId, FeeType feeType) external view returns (uint256);
    function getAllFees(uint64 ticketId, FeeType feeType)
        external
        view
        returns (uint256 ticketFee, uint256 hostItFee, uint256 totalFee);

    function getTicketBalance(uint64 ticketId, FeeType feeType) external view returns (uint256);

    function getHostItBalance(FeeType feeType) external view returns (uint256);

    function calculateHostItFee(uint256 fee) external view returns (uint256);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getRefundPeriod() external pure returns (uint256);
}
