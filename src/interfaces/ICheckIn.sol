// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

interface ICheckIn {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function checkIn(uint56 _ticketId, address _ticketOwner, uint256 _tokenId) external;

    function addTicketAdmins(uint56 _ticketId, address[] calldata _admins) external;

    function removeTicketAdmins(uint56 _ticketId, address[] calldata _admins) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isCheckedIn(uint56 _ticketId, address _ticketOwner) external view returns (bool);

    function isCheckedInForDay(uint56 _ticketId, uint8 _day, address _ticketOwner) external view returns (bool);

    function getCheckedIn(uint56 _ticketId) external view returns (address[] memory);

    function getCheckedInForDay(uint56 _ticketId, uint8 _day) external view returns (address[] memory);
}
