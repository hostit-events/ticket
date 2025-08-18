// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

interface IMarketplace {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function mintTicket(uint56 _ticketId, FeeType _feeType) external;

    function setTicketFees(uint56 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees) external;

    function withdrawTicketBalance(uint56 _ticketId, FeeType _feeType, address _to) external;

    function withdrawHostItBalance(FeeType _feeType, address _to) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isFeeEnabled(uint56 _ticketId, FeeType _feeType) external view returns (bool);

    function getFeeTokenAddress(FeeType _feeType) external view returns (address);

    function getTicketFee(uint56 _ticketId, FeeType _feeType) external view returns (uint256);

    function getTicketBalance(uint56 _ticketId, FeeType _feeType) external view returns (uint256);

    function getHostItBalance(FeeType _feeType) external view returns (uint256);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function calculateHostItFee(uint256 _fee) external pure returns (uint256);
}
