// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ContextLib} from "@diamond/libraries/ContextLib.sol";
import {AccessControlLib} from "@lattice/access/libraries/AccessControlLib.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {FeeType, MarketplaceLib, MarketplaceStorage} from "@ticket/libs/MarketplaceLib.sol";
import {LibClone} from "solady/utils/LibClone.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

event TicketCreated(uint64 indexed ticketId, address indexed ticketAdmin, ExtraTicketData ticketData);

event TicketUpdated(uint64 indexed ticketId, address indexed ticketAdmin, ExtraTicketData ticketData);

event TicketAdminAdded(uint64 indexed ticketId, address indexed admin);

event TicketAdminRemoved(uint64 indexed ticketId, address indexed admin);

error EmptyName();
error EmptyURI();
error StartTimeShouldBeAhead();
error EndTimeShouldBeAtLeastADayAfterStartTime();
error PurchaseStartTimeShouldBeAtLeastOneDayBeforeStartTime();
error MaxTicketsIsZero();
error TicketDoesNotExist(uint64);
error MaxTicketsShouldEqualSupply();
error TicketImplementationNotSet();
error UpdateNameFailed();
error UpdateSymbolFailed();
error UpdateURIFailed();
error TicketInitializationFailed();
error NoAdmins();
error AddressZeroAdmin();

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant FACTORY_STORAGE_LOCATION = 0x610b7ed6689c503e651500bb8179583591f93afc835ec7dbed5872619168c100;

/// @title FactoryStorage
/// @notice Storage structure for managing factory data
/// @custom:storage-location erc7201:host.it.ticket.factory.storage
struct FactoryStorage {
    address ticketProxy;
    uint64 ticketId;
    mapping(uint64 => ExtraTicketData) ticketIdToData;
    mapping(address => EnumerableSet.UintSet) adminTicketIds;
}

/// @title TicketData
/// @notice Struct representing ticket data
struct TicketData {
    uint48 startTime;
    uint48 endTime;
    uint48 purchaseStartTime;
    uint40 maxTickets;
    uint8 maxTicketsPerUser;
    bool isFree;
    bool isRefundable;
    string name;
    string symbol;
    string uri;
}

/// @title ExtraTicketData
/// @notice Struct representing extra ticket data
struct ExtraTicketData {
    uint64 id;
    uint48 createdAt;
    uint48 updatedAt;
    uint48 startTime;
    uint48 endTime;
    uint48 purchaseStartTime;
    uint40 maxTickets;
    uint40 soldTickets;
    uint8 maxTicketsPerUser;
    bool isFree;
    bool isRefundable;
    address ticketAdmin;
    address ticketAddress;
}

/// @title FullTicketData
/// @notice Struct representing full ticket data
struct FullTicketData {
    uint64 id;
    uint48 createdAt;
    uint48 updatedAt;
    uint48 startTime;
    uint48 endTime;
    uint48 purchaseStartTime;
    uint40 maxTickets;
    uint40 soldTickets;
    uint8 maxTicketsPerUser;
    bool isFree;
    bool isRefundable;
    address ticketAdmin;
    address ticketAddress;
    string name;
    string symbol;
    string uri;
}

library FactoryLib {
    using EnumerableSet for EnumerableSet.UintSet;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256("host.it.ticket")
    bytes32 private constant HOST_IT_TICKET = 0x2d39ca42f70b8fb1aad3b6b712ac8513c31a927ee8719e6858dd209fe8ec8293;
    // keccak256("host.it.ticket.main.admin")
    bytes32 private constant HOST_IT_MAIN_TICKET_ADMIN =
        0x9e43108e5493e42cc4760e9745ac2a20abf7b4bd5a1d7bd2109a5832e6ebfa95;
    // keccak256("host.it.ticket.admin")
    bytes32 private constant HOST_IT_TICKET_ADMIN = 0x66d6cfcd439cf68144fc7493914c7b690fcf4a642ab874f3276cb229bd8bcef2;

    function factoryStorage() internal pure returns (FactoryStorage storage fs_) {
        assembly {
            fs_.slot := FACTORY_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @param _fees {tok} per-ticket prices in each fee token
    /// @return ticketId_ {ticketId}
    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
        returns (uint64 ticketId_)
    {
        {
            if (bytes(_ticketData.name).length == 0) revert EmptyName();
            if (bytes(_ticketData.uri).length == 0) revert EmptyURI();

            // {s} < {s}
            if (_ticketData.startTime < SafeCastLib.toUint48(block.timestamp)) {
                revert StartTimeShouldBeAhead();
            }
            // {s} < {s} + {s}
            if (_ticketData.endTime < _ticketData.startTime + 24 hours) {
                revert EndTimeShouldBeAtLeastADayAfterStartTime();
            }
            // {s} > {s} - {s}
            if (_ticketData.purchaseStartTime > _ticketData.startTime - 24 hours) {
                revert PurchaseStartTimeShouldBeAtLeastOneDayBeforeStartTime();
            }
            if (_ticketData.maxTickets == 0) revert MaxTicketsIsZero();
        }

        FactoryStorage storage fs = factoryStorage();
        ticketId_ = ++fs.ticketId; // {ticketId}
        address ticketAdmin = ContextLib.msgSender(); // {addr}
        _grantTicketAdminRoles(ticketAdmin, ticketId_);

        ExtraTicketData memory extraTicketData = _createExtraTicketData(fs, _ticketData, ticketId_, ticketAdmin);
        fs.ticketIdToData[ticketId_] = extraTicketData;
        fs.adminTicketIds[ticketAdmin].add(ticketId_);

        if (!_ticketData.isFree) {
            MarketplaceLib.setTicketFees(ticketId_, _feeTypes, _fees);
        }

        emit TicketCreated(ticketId_, ticketAdmin, extraTicketData);
    }

    /// @param _ticketId {ticketId}
    function updateTicket(TicketData calldata _ticketData, uint64 _ticketId) internal {
        checkTicketExists(_ticketId);
        AccessControlLib.checkRole(generateMainTicketAdminRole(_ticketId));

        ExtraTicketData memory extraTicketData = getExtraTicketData(_ticketId);

        if (_ticketData.startTime != 0) {
            // {s} < {s}
            if (_ticketData.startTime < SafeCastLib.toUint48(block.timestamp)) {
                revert StartTimeShouldBeAhead();
            }
            extraTicketData.startTime = _ticketData.startTime; // {s}
        }

        if (_ticketData.endTime != 0) {
            // {s} < {s} + {s}
            if (_ticketData.endTime < extraTicketData.startTime + 1 days) {
                revert EndTimeShouldBeAtLeastADayAfterStartTime();
            }
            extraTicketData.endTime = _ticketData.endTime; // {s}
        }

        if (_ticketData.purchaseStartTime != 0) {
            // {s} > {s} - {s}
            if (_ticketData.purchaseStartTime > extraTicketData.startTime - 1 days) {
                revert PurchaseStartTimeShouldBeAtLeastOneDayBeforeStartTime();
            }
            extraTicketData.purchaseStartTime = _ticketData.purchaseStartTime; // {s}
        }

        if (_ticketData.maxTicketsPerUser > 0) {
            extraTicketData.maxTicketsPerUser = _ticketData.maxTicketsPerUser; // {ticket}
        }

        ITicket ticket = ITicket(extraTicketData.ticketAddress);
        if (_ticketData.maxTickets > 0) {
            // {ticket} < {ticket}
            if (_ticketData.maxTickets < ticket.totalSupply()) {
                revert MaxTicketsShouldEqualSupply();
            }
            extraTicketData.maxTickets = _ticketData.maxTickets; // {ticket}
        }

        extraTicketData.updatedAt = uint48(block.timestamp); // {s}
        factoryStorage().ticketIdToData[_ticketId] = extraTicketData;

        if (bytes(_ticketData.name).length > 0) {
            try ticket.updateName(_ticketData.name) {}
            catch {
                revert UpdateNameFailed();
            }
        }

        if (bytes(_ticketData.symbol).length > 0) {
            try ticket.updateSymbol(_ticketData.symbol) {}
            catch {
                revert UpdateSymbolFailed();
            }
        }

        if (bytes(_ticketData.uri).length > 0) {
            try ticket.updateURI(_ticketData.uri) {}
            catch {
                revert UpdateURIFailed();
            }
        }

        emit TicketUpdated(_ticketId, ContextLib.msgSender(), extraTicketData);
    }

    function addTicketAdmins(uint64 _ticketId, address[] calldata _admins) internal {
        checkTicketExists(_ticketId);
        checkMainTicketAdminRole(_ticketId);

        uint256 adminsLength = _admins.length;
        if (adminsLength == 0) revert NoAdmins();
        bytes32 ticketAdminRole = generateTicketAdminRole(_ticketId);
        for (uint256 i; i < adminsLength; ++i) {
            if (_admins[i] == address(0)) revert AddressZeroAdmin();
            AccessControlLib._grantRole(ticketAdminRole, _admins[i]);
            emit TicketAdminAdded(_ticketId, _admins[i]);
        }
    }

    function removeTicketAdmins(uint64 _ticketId, address[] calldata _admins) internal {
        checkTicketExists(_ticketId);
        checkMainTicketAdminRole(_ticketId);

        uint256 adminsLength = _admins.length;
        if (adminsLength == 0) revert NoAdmins();
        bytes32 ticketAdminRole = generateTicketAdminRole(_ticketId);
        for (uint256 i; i < adminsLength; ++i) {
            if (_admins[i] == address(0)) revert AddressZeroAdmin();
            AccessControlLib._revokeRole(ticketAdminRole, _admins[i]);
            emit TicketAdminRemoved(_ticketId, _admins[i]);
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                         INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _grantTicketAdminRoles(address _ticketAdmin, uint64 _ticketId) private {
        AccessControlLib._grantRole(generateMainTicketAdminRole(_ticketId), _ticketAdmin);
        AccessControlLib._grantRole(generateTicketAdminRole(_ticketId), _ticketAdmin);
    }

    function _createExtraTicketData(
        FactoryStorage storage _fs,
        TicketData calldata _ticketData,
        uint64 _ticketId,
        address _ticketAdmin
    ) private returns (ExtraTicketData memory extraTicketData_) {
        address ticketProxy = _fs.ticketProxy;
        if (ticketProxy.code.length == 0) revert TicketImplementationNotSet();
        address ticketAddress = LibClone.cloneDeterministic(ticketProxy, generateTicketHash(_ticketId));
        try ITicket(ticketAddress).initialize(address(this), _ticketData.name, _ticketData.symbol, _ticketData.uri) {}
        catch {
            revert TicketInitializationFailed();
        }

        extraTicketData_ = ExtraTicketData({
            id: _ticketId, // {ticketId}
            createdAt: uint48(block.timestamp), // {s}
            updatedAt: 0,
            startTime: _ticketData.startTime, // {s}
            endTime: _ticketData.endTime, // {s}
            purchaseStartTime: _ticketData.purchaseStartTime, // {s}
            maxTickets: _ticketData.maxTickets, // {ticket}
            soldTickets: 0, // {ticket}
            maxTicketsPerUser: _ticketData.maxTicketsPerUser, // {ticket}
            isFree: _ticketData.isFree,
            isRefundable: _ticketData.isRefundable,
            ticketAdmin: _ticketAdmin, // {addr}
            ticketAddress: ticketAddress // {addr}
        });
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @return {ticketId} total ticket type count
    function getTicketCount() internal view returns (uint64) {
        return factoryStorage().ticketId;
    }

    function ticketExists(uint64 _ticketId) internal view returns (bool) {
        return _ticketId > 0 && _ticketId <= getTicketCount();
    }

    function checkTicketExists(uint64 _ticketId) internal view {
        if (!ticketExists(_ticketId)) revert TicketDoesNotExist(_ticketId);
    }

    function getExtraTicketData(uint64 _ticketId) internal view returns (ExtraTicketData memory) {
        checkTicketExists(_ticketId);
        return factoryStorage().ticketIdToData[_ticketId];
    }

    function getFullTicketData(uint64 _ticketId) internal view returns (FullTicketData memory) {
        ExtraTicketData memory extraTicketData = getExtraTicketData(_ticketId);
        ITicket ticket = ITicket(extraTicketData.ticketAddress);
        return FullTicketData({
            id: extraTicketData.id,
            createdAt: extraTicketData.createdAt,
            updatedAt: extraTicketData.updatedAt,
            startTime: extraTicketData.startTime,
            endTime: extraTicketData.endTime,
            purchaseStartTime: extraTicketData.purchaseStartTime,
            maxTickets: extraTicketData.maxTickets,
            soldTickets: extraTicketData.soldTickets,
            maxTicketsPerUser: extraTicketData.maxTicketsPerUser,
            isFree: extraTicketData.isFree,
            isRefundable: extraTicketData.isRefundable,
            ticketAdmin: extraTicketData.ticketAdmin,
            ticketAddress: extraTicketData.ticketAddress,
            name: ticket.name(),
            symbol: ticket.symbol(),
            uri: ticket.baseURI()
        });
    }

    function getAllFullTicketData() internal view returns (FullTicketData[] memory fullTicketData_) {
        uint64 ticketCount = getTicketCount();
        fullTicketData_ = new FullTicketData[](ticketCount);

        for (uint64 i; i < ticketCount; ++i) {
            fullTicketData_[i] = getFullTicketData(i + 1);
        }
    }

    function getAdminTicketIds(address _ticketAdmin) internal view returns (uint64[] memory adminTicketIds_) {
        uint256[] memory adminTicketIds = factoryStorage().adminTicketIds[_ticketAdmin].values();
        assembly {
            adminTicketIds_ := adminTicketIds
        }
    }

    function getAdminFullTicketData(address _ticketAdmin)
        internal
        view
        returns (FullTicketData[] memory fullTicketData_)
    {
        uint64[] memory adminTicketIds = getAdminTicketIds(_ticketAdmin);
        uint64 ticketCount = uint64(adminTicketIds.length);
        fullTicketData_ = new FullTicketData[](ticketCount);
        for (uint64 i; i < ticketCount; ++i) {
            fullTicketData_[i] = getFullTicketData(adminTicketIds[i]);
        }
    }

    function isTicketFree(uint64 _ticketId) internal view returns (bool) {
        return factoryStorage().ticketIdToData[_ticketId].isFree;
    }

    function checkMainTicketAdminRole(uint64 _ticketId) internal view {
        AccessControlLib.checkRole(generateMainTicketAdminRole(_ticketId));
    }

    function checkTicketAdminRole(uint64 _ticketId) internal view {
        AccessControlLib.checkRole(generateTicketAdminRole(_ticketId));
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getHostItTicketHash() internal pure returns (bytes32) {
        return HOST_IT_TICKET;
    }

    function generateTicketHash(uint64 _ticketId) internal pure returns (bytes32 ticketHash_) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, HOST_IT_TICKET)
            mstore(add(ptr, 0x20), _ticketId)
            ticketHash_ := keccak256(ptr, 0x40)
        }
    }

    function generateMainTicketAdminRole(uint64 _ticketId) internal pure returns (bytes32 mainTicketAdminRole_) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, HOST_IT_MAIN_TICKET_ADMIN)
            mstore(add(ptr, 0x20), _ticketId)
            mainTicketAdminRole_ := keccak256(ptr, 0x40)
        }
    }

    function generateTicketAdminRole(uint64 _ticketId) internal pure returns (bytes32 ticketAdminRole_) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, HOST_IT_TICKET_ADMIN)
            mstore(add(ptr, 0x20), _ticketId)
            ticketAdminRole_ := keccak256(ptr, 0x40)
        }
    }
}
