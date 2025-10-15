// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

/// @title ICheckIn
/// @notice Interface for checking in tickets
interface ICheckIn {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Checks in a ticket for a user
    /// @param _ticketId The ID of the ticket to check in
    /// @param _ticketOwner The owner of the ticket
    /// @param _tokenId The token ID of the ticket
    function checkIn(uint64 _ticketId, address _ticketOwner, uint40 _tokenId) external;

    /// @notice Adds ticket admins to a ticket
    /// @param _ticketId The ID of the ticket to add admins to
    /// @param _admins The addresses of the admins to add
    function addTicketAdmins(uint64 _ticketId, address[] calldata _admins) external;

    /// @notice Removes ticket admins from a ticket
    /// @param _ticketId The ID of the ticket to remove admins from
    /// @param _admins The addresses of the admins to remove
    function removeTicketAdmins(uint64 _ticketId, address[] calldata _admins) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Checks if a ticket is checked in for a user
    /// @param _ticketId The ID of the ticket to check
    /// @param _ticketOwner The owner of the ticket
    function isCheckedIn(uint64 _ticketId, address _ticketOwner) external view returns (bool);

    /// @notice Checks if a ticket is checked in for a user on a specific day
    /// @param _ticketId The ID of the ticket to check
    /// @param _day The day to check
    /// @param _ticketOwner The owner of the ticket
    function isCheckedInForDay(uint64 _ticketId, uint8 _day, address _ticketOwner) external view returns (bool);

    /// @notice Gets the list of users who have checked in for a ticket
    /// @param _ticketId The ID of the ticket to get checked in users for
    function getCheckedIn(uint64 _ticketId) external view returns (address[] memory);

    /// @notice Gets the list of users who have checked in for a ticket on a specific day
    /// @param _ticketId The ID of the ticket to get checked in users for
    /// @param _day The day to get checked in users for
    function getCheckedInForDay(uint64 _ticketId, uint8 _day) external view returns (address[] memory);
}
