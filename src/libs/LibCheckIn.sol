// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {CheckInStorage, CHECKIN_STORAGE_LOCATION} from "@ticket-storage/CheckInStorage.sol";
import {LibFactory} from "@ticket/libs/LibFactory.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {ExtraTicketData} from "@ticket-storage/FactoryStorage.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-errors/CheckInErrors.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/CheckInLogs.sol";

library LibCheckIn {
    using LibFactory for uint56;
    using LibOwnableRoles for *;
    using EnumerableSet for EnumerableSet.AddressSet;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    function _checkInStorage() internal pure returns (CheckInStorage storage cs_) {
        assembly {
            cs_.slot := CHECKIN_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _checkin(uint56 _ticketId, address _ticketOwner, uint256 _tokenId) internal onlyTicketAdmin(_ticketId) {
        _ticketId._checkTicketExists();

        uint40 time = uint40(block.timestamp);
        ExtraTicketData memory ticketData = _ticketId._getExtraTicketData();

        if (time < ticketData.startTime) revert TicketUsePeriodNotStarted();
        if (time > ticketData.endTime) revert TicketUsePeriodHasEnded();

        ITicket ticket = ITicket(ticketData.ticketAddress);
        if (ticket.ownerOf(_tokenId) != _ticketOwner) revert NotTicketOwner(_tokenId);

        if (!ticket.paused()) {
            try ticket.pause() {}
            catch {
                revert TicketPauseFailed();
            }
        }

        CheckInStorage storage cs = _checkInStorage();

        cs.checkedIn[_ticketId].add(_ticketOwner);

        uint8 day = uint8((time - ticketData.startTime) / 1 days);
        if (!cs.checkedInByDay[_ticketId][day].add(_ticketOwner)) revert AlreadyCheckedInForDay(day);

        emit CheckedIn(_ticketId, _ticketOwner, _tokenId);
    }

    function _addTicketAdmins(uint56 _ticketId, address[] calldata _admins) internal onlyMainTicketAdmin(_ticketId) {
        _ticketId._checkTicketExists();

        uint256 adminsLength = _admins.length;
        if (adminsLength == 0) revert NoAdmins();
        uint256 ticketAdminRole = _ticketId._generateTicketAdminRole();
        for (uint256 i; i < adminsLength; ++i) {
            if (_admins[i] == address(0)) revert AddressZeroAdmin();
            _admins[i]._grantRoles(ticketAdminRole);
            emit TicketAdminAdded(_ticketId, _admins[i]);
        }
    }

    function _removeTicketAdmins(uint56 _ticketId, address[] calldata _admins)
        internal
        onlyMainTicketAdmin(_ticketId)
    {
        _ticketId._checkTicketExists();

        uint256 adminsLength = _admins.length;
        if (adminsLength == 0) revert NoAdmins();
        uint256 ticketAdminRole = _ticketId._generateTicketAdminRole();
        for (uint256 i; i < adminsLength; ++i) {
            if (_admins[i] == address(0)) revert AddressZeroAdmin();
            _admins[i]._removeRoles(ticketAdminRole);
            emit TicketAdminRemoved(_ticketId, _admins[i]);
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    function _isCheckedIn(uint56 _ticketId, address _ticketOwner) internal view returns (bool) {
        return _checkInStorage().checkedIn[_ticketId].contains(_ticketOwner);
    }

    function _isCheckedInForDay(uint56 _ticketId, uint8 _day, address _ticketOwner) internal view returns (bool) {
        return _checkInStorage().checkedInByDay[_ticketId][_day].contains(_ticketOwner);
    }

    function _getCheckedIn(uint56 _ticketId) internal view returns (address[] memory) {
        return _checkInStorage().checkedIn[_ticketId].values();
    }

    function _getCheckedInForDay(uint56 _ticketId, uint8 _day) internal view returns (address[] memory) {
        return _checkInStorage().checkedInByDay[_ticketId][_day].values();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyMainTicketAdmin(uint56 _ticketId) {
        LibFactory._checkMainTicketAdminRole(_ticketId);
        _;
    }

    modifier onlyTicketAdmin(uint56 _ticketId) {
        LibFactory._checkTicketAdminRole(_ticketId);
        _;
    }
}
