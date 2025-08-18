// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketData, FullTicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

interface IFactory {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external;

    function updateTicket(TicketData calldata _ticketData, uint56 _ticketId) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function ticketCount() external view returns (uint56);

    function ticketExists(uint56 _ticketId) external view returns (bool);

    function ticketData(uint56 _ticketId) external view returns (FullTicketData memory);

    function allTicketData() external view returns (FullTicketData[] memory);

    function adminTickets(address _ticketAdmin) external view returns (uint56[] memory);

    function adminTicketData(address _ticketAdmin) external view returns (FullTicketData[] memory);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function hostItTicketHash() external pure returns (bytes32);

    function ticketHash(uint56 _ticketId) external pure returns (bytes32);

    function mainAdminRole(uint56 _ticketId) external pure returns (uint256);

    function ticketAdminRole(uint56 _ticketId) external pure returns (uint256);
}
