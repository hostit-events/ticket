// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ICheckIn} from "@ticket/interfaces/ICheckIn.sol";
import {CheckInLib} from "@ticket/libs/CheckInLib.sol";

contract CheckInFacet is ICheckIn {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function checkIn(uint64 _ticketId, uint40 _tokenId) external {
        CheckInLib.checkin(_ticketId, _tokenId);
    }

    function checkInBatch(uint64 _ticketId, uint40[] calldata _tokenIds) external {
        CheckInLib.checkinBatch(_ticketId, _tokenIds);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function isCheckedIn(uint64 _ticketId, address _ticketOwner) external view returns (bool) {
        return CheckInLib.isCheckedIn(_ticketId, _ticketOwner);
    }

    function isCheckedInForDay(uint64 _ticketId, uint8 _day, address _ticketOwner) external view returns (bool) {
        return CheckInLib.isCheckedInForDay(_ticketId, _day, _ticketOwner);
    }

    function getCheckedIn(uint64 _ticketId) external view returns (address[] memory) {
        return CheckInLib.getCheckedIn(_ticketId);
    }

    function getCheckedInForDay(uint64 _ticketId, uint8 _day) external view returns (address[] memory) {
        return CheckInLib.getCheckedInForDay(_ticketId, _day);
    }
}
