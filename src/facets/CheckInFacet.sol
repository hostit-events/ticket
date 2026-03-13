// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ICheckIn} from "@ticket/interfaces/ICheckIn.sol";
import {LibCheckIn} from "@ticket/libs/LibCheckIn.sol";

contract CheckInFacet is ICheckIn {
    using LibCheckIn for uint64;

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function checkIn(uint64 _ticketId, address _ticketOwner, uint40 _tokenId) external {
        _ticketId._checkin(_ticketOwner, _tokenId);
    }

    function addTicketAdmins(uint64 _ticketId, address[] calldata _admins) external {
        _ticketId._addTicketAdmins(_admins);
    }

    function removeTicketAdmins(uint64 _ticketId, address[] calldata _admins) external {
        _ticketId._removeTicketAdmins(_admins);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isCheckedIn(uint64 _ticketId, address _ticketOwner) external view returns (bool) {
        return _ticketId._isCheckedIn(_ticketOwner);
    }

    function isCheckedInForDay(uint64 _ticketId, uint8 _day, address _ticketOwner) external view returns (bool) {
        return _ticketId._isCheckedInForDay(_day, _ticketOwner);
    }

    function getCheckedIn(uint64 _ticketId) external view returns (address[] memory) {
        return _ticketId._getCheckedIn();
    }

    function getCheckedInForDay(uint64 _ticketId, uint8 _day) external view returns (address[] memory) {
        return _ticketId._getCheckedInForDay(_day);
    }
}
