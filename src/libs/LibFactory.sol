// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketCreated, TicketUpdated} from "@host-it-logs/FactoryLogs.sol";
import {
    FactoryStorage,
    TicketData,
    TicketMetadata,
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
    // keccak256(abi.encodePacked("host.it.ticket", "host.it.main.ticket.admin"))
    bytes32 private constant HOST_IT_MAIN_TICKET_ADMIN =
        0x320d4f892a9fa49419e4feee48f2a920a83fd979077ea864d83915adeab12b63;
    // keccak256(abi.encodePacked("host.it.ticket", "host.it.ticket.admin"))
    bytes32 private constant HOST_IT_TICKET_ADMIN = 0x447358aa3307d72e4c4aa71aedd329ffff8d09e5fd1ca46ed8beeba02a9369ef;

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
        uint40 ticketId = ++$.ticketId;
        address ticketAdmin = LibContext._msgSender();
        ticketAdmin._grantTicketAdminRoles(ticketId);

        TicketMetadata memory ticketMetadata = _ticketData._createTicketMetadata(ticketId, ticketAdmin);
        $.ticketIdToData[ticketId] = ticketMetadata;
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

        emit TicketCreated(ticketId, ticketAdmin, ticketMetadata);
    }

    function _updateTicket(TicketData calldata _ticketData, uint40 _ticketId) internal {
        _ticketId._ticketExists();
        _generateMainTicketAdminRole(_ticketId)._checkRoles();

        TicketMetadata memory ticketMetadata = _getTicketMetadata(_ticketId);

        uint40 currentTime = uint40(block.timestamp);
        if (currentTime > ticketMetadata.startTime) revert TicketUseHasCommenced();

        if (_ticketData.startTime > 0) {
            if (_ticketData.startTime < currentTime) revert StartTimeShouldBeAhead();
            ticketMetadata.startTime = _ticketData.startTime;
        }

        if (_ticketData.endTime > 0) {
            if (_ticketData.endTime < _ticketData.startTime + 1 days) revert EndTimeShouldBeOneDayAfterStartTime();
            ticketMetadata.endTime = _ticketData.endTime;
        }

        if (_ticketData.purchaseStartTime > 0) {
            if (_ticketData.purchaseStartTime > _ticketData.startTime - 1 days) {
                revert PurchaseStartTimeShouldBeOneDayBeforeStartTime();
            }
            ticketMetadata.purchaseStartTime = _ticketData.purchaseStartTime;
        }

        Ticket ticket = Ticket(ticketMetadata.ticketAddress);
        if (_ticketData.maxTickets > 0) {
            if (_ticketData.maxTickets < ticket.totalSupply()) revert MaxTicketsShouldEqualSupply();
            ticketMetadata.maxTickets = _ticketData.maxTickets;
        }

        ticketMetadata.isFree = _ticketData.isFree;
        ticketMetadata.updatedAt = currentTime;
        _factoryStorage().ticketIdToData[_ticketId] = ticketMetadata;

        if (bytes(_ticketData.name).length > 0) ticket.updateName(_ticketData.name);
        if (bytes(_ticketData.symbol).length > 0) ticket.updateSymbol(_ticketData.symbol);
        if (bytes(_ticketData.uri).length > 0) ticket.updateURI(_ticketData.uri);

        emit TicketUpdated(_ticketId, LibContext._msgSender(), ticketMetadata);
    }

    function _grantTicketAdminRoles(address _ticketAdmin, uint40 _ticketId) internal {
        _ticketAdmin._grantRoles(_ticketId._generateMainTicketAdminRole());
        _ticketAdmin._grantRoles(_ticketId._generateTicketAdminRole());
    }

    function _createTicketMetadata(TicketData calldata _ticketData, uint40 _ticketId, address _ticketAdmin)
        internal
        returns (TicketMetadata memory ticketMetadata_)
    {
        address ticketImplementation = _factoryStorage().ticketImplementation;
        if (ticketImplementation.code.length == 0) revert("");
        address ticketAddress = ticketImplementation.cloneDeterministic(_generateTicketHash(_ticketId));
        Ticket(ticketAddress).initialize(address(this), _ticketData.name, _ticketData.uri);

        ticketMetadata_ = TicketMetadata({
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

    function _getTicketCount() internal view returns (uint40) {
        return LibFactory._factoryStorage().ticketId;
    }

    function _ticketExists(uint40 _ticketId) internal view returns (bool status_) {
        status_ = _ticketId > 0 && _ticketId <= _getTicketCount();
        if (!status_) revert TicketDoesNotExist(_ticketId);
    }

    function _getTicketMetadata(uint40 _ticketId) internal view returns (TicketMetadata memory ticketMetadata_) {
        _ticketId._ticketExists();
        ticketMetadata_ = _factoryStorage().ticketIdToData[_ticketId];
    }

    function _getFullTicketData(uint40 _ticketId) internal view returns (FullTicketData memory fullTicketData_) {
        TicketMetadata memory ticketMetadata = _getTicketMetadata(_ticketId);
        Ticket ticket = Ticket(ticketMetadata.ticketAddress);
        fullTicketData_ = FullTicketData({
            id: ticketMetadata.id,
            createdAt: ticketMetadata.createdAt,
            updatedAt: ticketMetadata.updatedAt,
            startTime: ticketMetadata.startTime,
            endTime: ticketMetadata.endTime,
            purchaseStartTime: ticketMetadata.purchaseStartTime,
            maxTickets: ticketMetadata.maxTickets,
            soldTickets: ticketMetadata.soldTickets,
            isFree: ticketMetadata.isFree,
            ticketAdmin: ticketMetadata.ticketAdmin,
            ticketAddress: ticketMetadata.ticketAddress,
            name: ticket.name(),
            symbol: ticket.symbol(),
            uri: ticket.baseURI()
        });
    }

    function _getAllFullTicketData() internal view returns (FullTicketData[] memory fullTicketData_) {
        uint40 ticketCount = _getTicketCount();
        fullTicketData_ = new FullTicketData[](ticketCount);

        for (uint40 i; i < ticketCount; ++i) {
            fullTicketData_[i] = _getFullTicketData(i + 1);
        }
    }

    function _getAdminTicketIds(address _ticketAdmin) internal view returns (uint40[] memory adminTicketIds_) {
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
        uint40[] memory adminTicketIds = _getAdminTicketIds(_ticketAdmin);
        uint40 ticketCount = uint40(adminTicketIds.length);
        fullTicketData_ = new FullTicketData[](ticketCount);
        for (uint40 i; i < ticketCount; ++i) {
            fullTicketData_[i] = adminTicketIds[i]._getFullTicketData();
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getHostItTicketHash() internal pure returns (bytes32) {
        return HOST_IT_TICKET;
    }

    function _generateTicketHash(uint40 _ticketId) internal pure returns (bytes32 ticketHash_) {
        bytes memory ticket = abi.encodePacked(HOST_IT_TICKET, _ticketId);
        assembly {
            ticketHash_ := keccak256(add(ticket, 0x20), mload(ticket))
        }
    }

    function _generateMainTicketAdminRole(uint40 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(HOST_IT_MAIN_TICKET_ADMIN, _ticketId)));
    }

    function _generateTicketAdminRole(uint40 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(HOST_IT_TICKET_ADMIN, _ticketId)));
    }
}
