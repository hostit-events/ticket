// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {ExtraTicketData, FactoryLib} from "@ticket/libs/FactoryLib.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

//*//////////////////////////////////////////////////////////////////////////
//                                   EVENTS
//////////////////////////////////////////////////////////////////////////*//

event CheckedIn(uint64 indexed ticketId, address indexed ticketOwner, uint8 indexed day, uint40 tokenId);

//*//////////////////////////////////////////////////////////////////////////
//                                   ERRORS
//////////////////////////////////////////////////////////////////////////*//

error TicketUsePeriodNotStarted();
error TicketUsePeriodHasEnded();
error AlreadyCheckedInForDay(uint8);
error TicketCallFailed();
error EmptyBatch();

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
    /// @param _tokenId {ticket}
    function checkin(uint64 _ticketId, uint40 _tokenId) internal onlyTicketAdmin(_ticketId) {
        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);
        uint48 time = SafeCastLib.toUint48(block.timestamp); // {s}

        if (time < ticketData.startTime) revert TicketUsePeriodNotStarted();
        if (time > ticketData.endTime) revert TicketUsePeriodHasEnded();

        ITicket ticket = ITicket(ticketData.ticketAddress);
        ticket.useTicket(_tokenId);

        // {day} = ({s} - {s}) / {s}
        uint8 day = uint8((time - ticketData.startTime) / 1 days);
        _recordCheckIn(checkInStorage(), _ticketId, day, ticket.ownerOf(_tokenId), _tokenId);
    }

    /// @param _ticketId {ticketId}
    /// @param _tokenIds {ticket}[] tokens whose holders should be marked checked-in
    function checkinBatch(uint64 _ticketId, uint40[] calldata _tokenIds) internal onlyTicketAdmin(_ticketId) {
        uint256 len = _tokenIds.length;
        if (len == 0) revert EmptyBatch();

        ExtraTicketData memory ticketData = FactoryLib.getExtraTicketData(_ticketId);
        uint48 time = SafeCastLib.toUint48(block.timestamp); // {s}

        if (time < ticketData.startTime) revert TicketUsePeriodNotStarted();
        if (time > ticketData.endTime) revert TicketUsePeriodHasEnded();

        ITicket ticket = ITicket(ticketData.ticketAddress);

        // {day} = ({s} - {s}) / {s}
        uint8 day = uint8((time - ticketData.startTime) / 1 days);
        CheckInStorage storage cs = checkInStorage();

        for (uint256 i; i < len; ++i) {
            uint40 tokenId = _tokenIds[i];
            ticket.useTicket(tokenId);
            _recordCheckIn(cs, _ticketId, day, ticket.ownerOf(tokenId), tokenId);
        }
    }

    function _recordCheckIn(CheckInStorage storage _cs, uint64 _ticketId, uint8 _day, address _ticketOwner, uint40 _tokenId)
        private
    {
        _cs.checkedIn[_ticketId].add(_ticketOwner);
        if (!_cs.checkedInByDay[_ticketId][_day].add(_ticketOwner)) revert AlreadyCheckedInForDay(_day);
        emit CheckedIn(_ticketId, _ticketOwner, _day, _tokenId);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Checks if the specified address has checked in for the specified ticket
    /// @param _ticketId The ID of the ticket
    /// @param _ticketOwner The address of the ticket owner to check
    /// @return True if the address has checked in, false otherwise
    function isCheckedIn(uint64 _ticketId, address _ticketOwner) internal view returns (bool) {
        return checkInStorage().checkedIn[_ticketId].contains(_ticketOwner);
    }

    /// @notice Checks if the specified address has checked in for the specified ticket and day
    /// @param _ticketId The ID of the ticket
    /// @param _day The day for which to check
    /// @param _ticketOwner The address of the ticket owner to check
    /// @return True if the address has checked in, false otherwise
    function isCheckedInForDay(uint64 _ticketId, uint8 _day, address _ticketOwner) internal view returns (bool) {
        return checkInStorage().checkedInByDay[_ticketId][_day].contains(_ticketOwner);
    }

    /// @notice Gets the list of addresses that have checked in for the specified ticket
    /// @param _ticketId The ID of the ticket
    function getCheckedIn(uint64 _ticketId) internal view returns (address[] memory) {
        return checkInStorage().checkedIn[_ticketId].values();
    }

    /// @param _day {day}
    /// @notice Gets the list of addresses that have checked in for the specified ticket and day
    /// @param _ticketId The ID of the ticket
    /// @param _day The day for which to get checked-in addresses
    function getCheckedInForDay(uint64 _ticketId, uint8 _day) internal view returns (address[] memory) {
        return checkInStorage().checkedInByDay[_ticketId][_day].values();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    modifier onlyTicketAdmin(uint64 _ticketId) {
        FactoryLib.checkTicketAdminRole(_ticketId);
        _;
    }
}
