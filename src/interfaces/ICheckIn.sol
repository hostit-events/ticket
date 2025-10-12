// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

interface ICheckIn {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function checkIn(uint64 _ticketId, address _ticketOwner, uint256 _tokenId) external;

    function addTicketAdmins(uint64 _ticketId, address[] calldata _admins) external;

    function removeTicketAdmins(uint64 _ticketId, address[] calldata _admins) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isCheckedIn(uint64 _ticketId, address _ticketOwner) external view returns (bool);

    function isCheckedInForDay(uint64 _ticketId, uint8 _day, address _ticketOwner) external view returns (bool);

    function getCheckedIn(uint64 _ticketId) external view returns (address[] memory);

    function getCheckedInForDay(uint64 _ticketId, uint8 _day) external view returns (address[] memory);
}
