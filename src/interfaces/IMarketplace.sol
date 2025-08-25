// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

interface IMarketplace {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function mintTicket(uint56 ticketId, FeeType feeType, address buyer) external payable returns (uint40);

    function setTicketFees(uint56 ticketId, FeeType[] calldata feeTypes, uint256[] calldata fees) external;

    function withdrawTicketBalance(uint56 ticketId, FeeType feeType, address to) external returns (address);

    function withdrawHostItBalance(FeeType feeType, address to) external returns (address);

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isFeeEnabled(uint56 ticketId, FeeType feeType) external view returns (bool);

    function getFeeTokenAddress(FeeType feeType) external view returns (address);

    function getTicketFee(uint56 ticketId, FeeType feeType) external view returns (uint256);
    function getAllFees(uint56 ticketId, FeeType feeType)
        external
        view
        returns (uint256 ticketFee, uint256 hostItFee, uint256 totalFee);

    function getTicketBalance(uint56 ticketId, FeeType feeType) external view returns (uint256);

    function getHostItBalance(FeeType feeType) external view returns (uint256);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function calculateHostItFee(uint256 fee) external pure returns (uint256);
    function getRefundPeriod() external pure returns (uint256);
}
