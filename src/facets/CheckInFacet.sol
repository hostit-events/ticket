// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {LibCheckIn} from "@host-it/libs/LibCheckIn.sol";

contract CheckInFacet {
    using LibCheckIn for uint56;

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function checkIn(uint56 _ticketId, address _ticketOwner, uint256 _tokenId) external {
        _ticketId._checkin(_ticketOwner, _tokenId);
    }

    function addTicketAdmins(uint56 _ticketId, address[] calldata _admins) external {
        _ticketId._addTicketAdmins(_admins);
    }

    function removeTicketAdmins(uint56 _ticketId, address[] calldata _admins) external {
        _ticketId._removeTicketAdmins(_admins);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isCheckedIn(uint56 _ticketId, address _ticketOwner) external view returns (bool) {
        return _ticketId._isCheckedIn(_ticketOwner);
    }

    function isCheckedInForDay(uint56 _ticketId, uint8 _day, address _ticketOwner) external view returns (bool) {
        return _ticketId._isCheckedInForDay(_day, _ticketOwner);
    }

    function getCheckedIn(uint56 _ticketId) external view returns (address[] memory) {
        return _ticketId._getCheckedIn();
    }

    function getCheckedInForDay(uint56 _ticketId, uint8 _day) external view returns (address[] memory) {
        return _ticketId._getCheckedInForDay(_day);
    }
}
