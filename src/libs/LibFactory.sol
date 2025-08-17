// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketCreated, TicketUpdated} from "@host-it-logs/FactoryLogs.sol";
import {
    FactoryStorage,
    TicketData,
    ExtraTicketData,
    FullTicketData,
    FACTORY_STORAGE_POSITION
} from "@host-it-storage/FactoryStorage.sol";
import {LibMarketplace} from "@host-it/libs/LibMarketplace.sol";
import {FeeType, MarketplaceStorage} from "@host-it-storage/MarketplaceStorage.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {LibContext} from "@host-it/libs/LibContext.sol";
import {Ticket} from "@host-it/Ticket.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@host-it-errors/FactoryErrors.sol";

library LibFactory {
    using LibFactory for *;
    using Clones for address;
    using {LibOwnableRoles._grantRoles} for address;
    using {LibOwnableRoles._checkRoles} for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
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

    function _factoryStorage() internal pure returns (FactoryStorage storage fs_) {
        assembly {
            fs_.slot := FACTORY_STORAGE_POSITION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
    {
        if (bytes(_ticketData.name).length == 0) revert EmptyName();
        if (bytes(_ticketData.uri).length == 0) revert EmptyURI();

        if (_ticketData.startTime < block.timestamp) revert StartTimeShouldBeAhead();
        if (_ticketData.endTime < _ticketData.startTime + 1 days) revert EndTimeShouldBeOneDayAfterStartTime();
        if (_ticketData.purchaseStartTime > _ticketData.startTime - 1 days) {
            revert PurchaseStartTimeShouldBeOneDayBeforeStartTime();
        }
        if (_ticketData.maxTickets == 0) revert MaxTicketsIsZero();

        FactoryStorage storage $ = _factoryStorage();
        uint56 ticketId = ++$.ticketId;
        address ticketAdmin = LibContext._msgSender();
        ticketAdmin._grantTicketAdminRoles(ticketId);

        ExtraTicketData memory extraTicketData = _ticketData._createExtraTicketData(ticketId, ticketAdmin);
        $.ticketIdToData[ticketId] = extraTicketData;
        $.adminTicketIds[ticketAdmin].add(ticketId);

        if (!_ticketData.isFree) {
            uint256 feeTypesLength = _feeTypes.length;
            if (feeTypesLength == 0 || feeTypesLength != _fees.length) revert ArrayMismatch();
            MarketplaceStorage storage mps = LibMarketplace._marketplaceStorage();
            for (uint256 i; i < feeTypesLength; ++i) {
                FeeType feeType = _feeTypes[i];
                if (mps.feeEnabled[ticketId][feeType]) revert FeeAlreadySet(feeType);

                if (_fees[i] == 0) revert ZeroFee(feeType);
                mps.feeEnabled[ticketId][feeType] = true;
                mps.ticketFee[ticketId][feeType] = _fees[i];
            }
        }

        emit TicketCreated(ticketId, ticketAdmin, extraTicketData);
    }

    function _updateTicket(TicketData calldata _ticketData, uint56 _ticketId) internal {
        _ticketId._ticketExists();
        _ticketId._generateMainTicketAdminRole()._checkRoles();

        ExtraTicketData memory extraTicketData = _getExtraTicketData(_ticketId);

        uint40 currentTime = uint40(block.timestamp);
        if (currentTime > extraTicketData.startTime) revert TicketUseHasCommenced();

        if (_ticketData.startTime > 0) {
            if (_ticketData.startTime < currentTime) revert StartTimeShouldBeAhead();
            extraTicketData.startTime = _ticketData.startTime;
        }

        if (_ticketData.endTime > 0) {
            if (_ticketData.endTime < _ticketData.startTime + 1 days) revert EndTimeShouldBeOneDayAfterStartTime();
            extraTicketData.endTime = _ticketData.endTime;
        }

        if (_ticketData.purchaseStartTime > 0) {
            if (_ticketData.purchaseStartTime > _ticketData.startTime - 1 days) {
                revert PurchaseStartTimeShouldBeOneDayBeforeStartTime();
            }
            extraTicketData.purchaseStartTime = _ticketData.purchaseStartTime;
        }

        Ticket ticket = Ticket(extraTicketData.ticketAddress);
        if (_ticketData.maxTickets > 0) {
            if (_ticketData.maxTickets < ticket.totalSupply()) revert MaxTicketsShouldEqualSupply();
            extraTicketData.maxTickets = _ticketData.maxTickets;
        }

        extraTicketData.isFree = _ticketData.isFree;
        extraTicketData.updatedAt = currentTime;
        _factoryStorage().ticketIdToData[_ticketId] = extraTicketData;

        if (bytes(_ticketData.name).length > 0) ticket.updateName(_ticketData.name);
        if (bytes(_ticketData.symbol).length > 0) ticket.updateSymbol(_ticketData.symbol);
        if (bytes(_ticketData.uri).length > 0) ticket.updateURI(_ticketData.uri);

        emit TicketUpdated(_ticketId, LibContext._msgSender(), extraTicketData);
    }

    function _grantTicketAdminRoles(address _ticketAdmin, uint56 _ticketId) internal {
        _ticketAdmin._grantRoles(_ticketId._generateMainTicketAdminRole());
        _ticketAdmin._grantRoles(_ticketId._generateTicketAdminRole());
    }

    function _createExtraTicketData(TicketData calldata _ticketData, uint56 _ticketId, address _ticketAdmin)
        internal
        returns (ExtraTicketData memory extraTicketData_)
    {
        address ticketImplementation = _factoryStorage().ticketImplementation;
        if (ticketImplementation.code.length == 0) revert TicketImplementationNotSet();
        address ticketAddress = ticketImplementation.cloneDeterministic(_generateTicketHash(_ticketId));
        Ticket(ticketAddress).initialize(address(this), _ticketData.name, _ticketData.uri);

        extraTicketData_ = ExtraTicketData({
            id: _ticketId,
            createdAt: uint40(block.timestamp),
            updatedAt: 0,
            startTime: uint40(_ticketData.startTime),
            endTime: uint40(_ticketData.endTime),
            purchaseStartTime: _ticketData.purchaseStartTime,
            maxTickets: uint40(_ticketData.maxTickets),
            soldTickets: 0,
            ticketAdmin: _ticketAdmin,
            ticketAddress: ticketAddress,
            isFree: _ticketData.isFree
        });
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getTicketCount() internal view returns (uint56) {
        return LibFactory._factoryStorage().ticketId;
    }

    function _ticketExists(uint56 _ticketId) internal view returns (bool status_) {
        status_ = _ticketId > 0 && _ticketId <= _getTicketCount();
        if (!status_) revert TicketDoesNotExist(_ticketId);
    }

    function _getExtraTicketData(uint56 _ticketId) internal view returns (ExtraTicketData memory extraTicketData_) {
        _ticketId._ticketExists();
        extraTicketData_ = _factoryStorage().ticketIdToData[_ticketId];
    }

    function _getFullTicketData(uint56 _ticketId) internal view returns (FullTicketData memory fullTicketData_) {
        ExtraTicketData memory extraTicketData = _getExtraTicketData(_ticketId);
        Ticket ticket = Ticket(extraTicketData.ticketAddress);
        fullTicketData_ = FullTicketData({
            id: extraTicketData.id,
            createdAt: extraTicketData.createdAt,
            updatedAt: extraTicketData.updatedAt,
            startTime: extraTicketData.startTime,
            endTime: extraTicketData.endTime,
            purchaseStartTime: extraTicketData.purchaseStartTime,
            maxTickets: extraTicketData.maxTickets,
            soldTickets: extraTicketData.soldTickets,
            isFree: extraTicketData.isFree,
            ticketAdmin: extraTicketData.ticketAdmin,
            ticketAddress: extraTicketData.ticketAddress,
            name: ticket.name(),
            symbol: ticket.symbol(),
            uri: ticket.baseURI()
        });
    }

    function _getAllFullTicketData() internal view returns (FullTicketData[] memory fullTicketData_) {
        uint56 ticketCount = _getTicketCount();
        fullTicketData_ = new FullTicketData[](ticketCount);

        for (uint56 i; i < ticketCount; ++i) {
            fullTicketData_[i] = _getFullTicketData(i + 1);
        }
    }

    function _getAdminTicketIds(address _ticketAdmin) internal view returns (uint56[] memory adminTicketIds_) {
        uint256[] memory adminTicketIds = _factoryStorage().adminTicketIds[_ticketAdmin].values();
        assembly {
            adminTicketIds_ := adminTicketIds
        }
    }

    function _getAdminFullTicketData(address _ticketAdmin)
        internal
        view
        returns (FullTicketData[] memory fullTicketData_)
    {
        uint56[] memory adminTicketIds = _getAdminTicketIds(_ticketAdmin);
        uint56 ticketCount = uint56(adminTicketIds.length);
        fullTicketData_ = new FullTicketData[](ticketCount);
        for (uint56 i; i < ticketCount; ++i) {
            fullTicketData_[i] = adminTicketIds[i]._getFullTicketData();
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getHostItTicketHash() internal pure returns (bytes32) {
        return HOST_IT_TICKET;
    }

    function _generateTicketHash(uint56 _ticketId) internal pure returns (bytes32 ticketHash_) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, HOST_IT_TICKET)
            mstore(add(ptr, 0x20), _ticketId)
            ticketHash_ := keccak256(ptr, 0x40)
        }
    }

    function _generateMainTicketAdminRole(uint56 _ticketId) internal pure returns (uint256 mainTicketAdminRole_) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, HOST_IT_MAIN_TICKET_ADMIN)
            mstore(add(ptr, 0x20), _ticketId)
            mainTicketAdminRole_ := keccak256(ptr, 0x40)
        }
    }

    function _generateTicketAdminRole(uint56 _ticketId) internal pure returns (uint256 ticketAdminRole_) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, HOST_IT_TICKET_ADMIN)
            mstore(add(ptr, 0x20), _ticketId)
            ticketAdminRole_ := keccak256(ptr, 0x40)
        }
    }
}
