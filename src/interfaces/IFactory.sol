// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FullTicketData, TicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

interface IFactory {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external;

    function updateTicket(TicketData calldata _ticketData, uint64 _ticketId) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function ticketCount() external view returns (uint64);

    function ticketExists(uint64 _ticketId) external view returns (bool);

    function ticketData(uint64 _ticketId) external view returns (FullTicketData memory);

    function allTicketData() external view returns (FullTicketData[] memory);

    function adminTickets(address _ticketAdmin) external view returns (uint64[] memory);

    function adminTicketData(address _ticketAdmin) external view returns (FullTicketData[] memory);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function hostItTicketHash() external pure returns (bytes32);

    function ticketHash(uint64 _ticketId) external pure returns (bytes32);

    function mainAdminRole(uint64 _ticketId) external pure returns (uint256);

    function ticketAdminRole(uint64 _ticketId) external pure returns (uint256);
}
