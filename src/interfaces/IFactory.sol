// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FullTicketData, TicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

/// @title IFactory
/// @notice Interface for the Factory facet
interface IFactory {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Creates a new ticket
    /// @param _ticketData The ticket data
    /// @param _feeTypes The fee types
    /// @param _fees The fees
    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external
        returns (uint64);

    /// @notice Updates an existing ticket
    /// @param _ticketData The ticket data
    /// @param _ticketId The ID of the ticket to update
    function updateTicket(TicketData calldata _ticketData, uint64 _ticketId) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Gets the total number of tickets
    /// @return The total number of tickets
    function ticketCount() external view returns (uint64);

    /// @notice Checks if a ticket exists
    /// @param _ticketId The ID of the ticket to check
    /// @return Whether the ticket exists
    function ticketExists(uint64 _ticketId) external view returns (bool);

    /// @notice Gets the ticket data for a ticket
    /// @param _ticketId The ID of the ticket to get data for
    /// @return The ticket data
    function ticketData(uint64 _ticketId) external view returns (FullTicketData memory);

    /// @notice Gets all ticket data
    /// @return All ticket data
    function allTicketData() external view returns (FullTicketData[] memory);

    /// @notice Gets the list of tickets for a ticket admin
    /// @param _ticketAdmin The ticket admin to get tickets for
    /// @return The list of tickets for the ticket admin
    function adminTickets(address _ticketAdmin) external view returns (uint64[] memory);

    /// @notice Gets the ticket data for a ticket admin
    /// @param _ticketAdmin The ticket admin to get ticket data for
    /// @return The ticket data for the ticket admin
    function adminTicketData(address _ticketAdmin) external view returns (FullTicketData[] memory);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Gets the hash of the HostIt ticket
    /// @return The hash of the HostIt ticket
    function hostItTicketHash() external pure returns (bytes32);

    /// @notice Gets the hash of a ticket
    /// @param _ticketId The ID of the ticket to get the hash for
    /// @return The hash of the ticket
    function ticketHash(uint64 _ticketId) external pure returns (bytes32);

    /// @notice Gets the main admin role for a ticket
    /// @param _ticketId The ID of the ticket to get the main admin role for
    /// @return The main admin role for the ticket
    function mainAdminRole(uint64 _ticketId) external pure returns (uint256);

    /// @notice Gets the ticket admin role for a ticket
    /// @param _ticketId The ID of the ticket to get the ticket admin role for
    /// @return The ticket admin role for the ticket
    function ticketAdminRole(uint64 _ticketId) external pure returns (uint256);
}
