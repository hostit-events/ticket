// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";
import {AccessControlLib} from "@lattice/access/libraries/AccessControlLib.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {ExtraTicketData, FactoryLib} from "@ticket/libs/FactoryLib.sol";

//*//////////////////////////////////////////////////////////////////////////
//                                   EVENTS
//////////////////////////////////////////////////////////////////////////*//

event CheckedIn(uint64 indexed ticketId, address indexed ticketOwner, uint40 tokenId);

event TicketAdminAdded(uint64 indexed ticketId, address indexed admin);

event TicketAdminRemoved(uint64 indexed ticketId, address indexed admin);

//*//////////////////////////////////////////////////////////////////////////
//                                   ERRORS
//////////////////////////////////////////////////////////////////////////*//

error TicketUsePeriodNotStarted();
error TicketUsePeriodHasEnded();
error NotTicketOwner(uint40);
error AlreadyCheckedInForDay(uint8);
error NoAdmins();
error AddressZeroAdmin();
error TicketPauseFailed();

//*//////////////////////////////////////////////////////////////////////////
//                              CHECKIN STORAGE
//////////////////////////////////////////////////////////////////////////*//

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.checkin.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant CHECKIN_STORAGE_LOCATION = 0xe193d680ae43ded63724eb4ee4d68fd7efbded9778d44414c0bab0177a079700;

/// @title CheckInStorage
/// @notice Storage structure for managing check-in data
/// @custom:storage-location erc7201:host.it.ticket.checkin.storage
struct CheckInStorage {
    mapping(uint64 => EnumerableSet.AddressSet) checkedIn;
    mapping(uint64 => mapping(uint8 => EnumerableSet.AddressSet)) checkedInByDay;
}

library CheckInLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    function checkInStorage() internal pure returns (CheckInStorage storage cs_) {
        assembly {
            cs_.slot := CHECKIN_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @param _ticketId {ticketId}
    /// @param _ticketOwner {addr}
    /// @param _tokenId {ticket}
    function checkin(uint64 _ticketId, address _ticketOwner, uint40 _tokenId) internal onlyTicketAdmin(_ticketId) {
        FactoryLib.checkTicketExists(_ticketId);

        uint40 time = uint40(block.timestamp); // {s}
        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);

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

        CheckInStorage storage cs = checkInStorage();

        cs.checkedIn[_ticketId].add(_ticketOwner);

        // {day} = ({s} - {s}) / {s}
        uint8 day = uint8((time - ticketData.startTime) / 1 days);
        if (!cs.checkedInByDay[_ticketId][day].add(_ticketOwner)) revert AlreadyCheckedInForDay(day);

        emit CheckedIn(_ticketId, _ticketOwner, _tokenId);
    }

    function addTicketAdmins(uint64 _ticketId, address[] calldata _admins) internal onlyMainTicketAdmin(_ticketId) {
        FactoryLib.checkTicketExists(_ticketId);

        uint256 adminsLength = _admins.length;
        if (adminsLength == 0) revert NoAdmins();
        bytes32 ticketAdminRole = FactoryLib.generateTicketAdminRole(_ticketId);
        for (uint256 i; i < adminsLength; ++i) {
            if (_admins[i] == address(0)) revert AddressZeroAdmin();
            AccessControlLib._grantRole(ticketAdminRole, _admins[i]);
            emit TicketAdminAdded(_ticketId, _admins[i]);
        }
    }

    function removeTicketAdmins(uint64 _ticketId, address[] calldata _admins) internal onlyMainTicketAdmin(_ticketId) {
        FactoryLib.checkTicketExists(_ticketId);

        uint256 adminsLength = _admins.length;
        if (adminsLength == 0) revert NoAdmins();
        bytes32 ticketAdminRole = FactoryLib.generateTicketAdminRole(_ticketId);
        for (uint256 i; i < adminsLength; ++i) {
            if (_admins[i] == address(0)) revert AddressZeroAdmin();
            AccessControlLib._revokeRole(ticketAdminRole, _admins[i]);
            emit TicketAdminRemoved(_ticketId, _admins[i]);
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    function isCheckedIn(uint64 _ticketId, address _ticketOwner) internal view returns (bool) {
        return checkInStorage().checkedIn[_ticketId].contains(_ticketOwner);
    }

    /// @param _day {day}
    function isCheckedInForDay(uint64 _ticketId, uint8 _day, address _ticketOwner) internal view returns (bool) {
        return checkInStorage().checkedInByDay[_ticketId][_day].contains(_ticketOwner);
    }

    function getCheckedIn(uint64 _ticketId) internal view returns (address[] memory) {
        return checkInStorage().checkedIn[_ticketId].values();
    }

    /// @param _day {day}
    function getCheckedInForDay(uint64 _ticketId, uint8 _day) internal view returns (address[] memory) {
        return checkInStorage().checkedInByDay[_ticketId][_day].values();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyMainTicketAdmin(uint64 _ticketId) {
        FactoryLib.checkMainTicketAdminRole(_ticketId);
        _;
    }

    modifier onlyTicketAdmin(uint64 _ticketId) {
        FactoryLib.checkTicketAdminRole(_ticketId);
        _;
    }
}
