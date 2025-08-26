// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketData, ExtraTicketData, FullTicketData} from "@ticket-storage/FactoryStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
import {TicketCreated, TicketUpdated} from "@ticket-logs/FactoryLogs.sol";

contract FactoryTest is DeployedHostItTickets {
    function test_createFreeTicket() public {
        ExtraTicketData memory extraTicketData;
        vm.expectEmit(true, true, true, false, hostIt);
        emit TicketCreated(1, owner, extraTicketData);
        _createFreeTicket();
        uint56 ticketId = factoryFacet.ticketCount();
        TicketData memory ticketData = _getFreeTicketData();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        assertTrue(factoryFacet.ticketExists(ticketId));
        assertEq(ticketId, 1);
        assertEq(fullTicketData.id, ticketId);
        assertEq(fullTicketData.createdAt, _currentTime);
        assertEq(fullTicketData.updatedAt, 0);
        assertEq(fullTicketData.startTime, ticketData.startTime);
        assertEq(fullTicketData.endTime, ticketData.endTime);
        assertEq(fullTicketData.purchaseStartTime, ticketData.purchaseStartTime);
        assertEq(fullTicketData.maxTickets, ticketData.maxTickets);
        assertEq(fullTicketData.soldTickets, 0);
        assertEq(fullTicketData.isFree, ticketData.isFree);
        assertEq(fullTicketData.ticketAdmin, owner);
        assertNotEq(fullTicketData.ticketAddress, address(0));
        assertEq(fullTicketData.name, ticketData.name);
        assertEq(fullTicketData.symbol, "TICKET");
        assertEq(fullTicketData.uri, ticketData.uri);
    }

    function test_updateFreeTicket() public {
        _createFreeTicket();
        uint56 ticketId = factoryFacet.ticketCount();
        TicketData memory ticketData = _getFreeUpdatedTicketData();
        vm.warp(10000);
        ExtraTicketData memory extraTicketData;
        vm.expectEmit(true, true, false, false, hostIt);
        emit TicketUpdated(ticketId, owner, extraTicketData);
        factoryFacet.updateTicket(ticketData, ticketId);
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        assertEq(fullTicketData.name, ticketData.name);
        assertEq(fullTicketData.symbol, ticketData.symbol);
        assertEq(fullTicketData.uri, ticketData.uri);
        assertEq(fullTicketData.startTime, ticketData.startTime);
        assertEq(fullTicketData.purchaseStartTime, ticketData.purchaseStartTime);
        assertEq(fullTicketData.maxTickets, ticketData.maxTickets);
        assertEq(fullTicketData.isFree, ticketData.isFree);
        assertEq(fullTicketData.createdAt, _currentTime);
        assertEq(fullTicketData.updatedAt, 10000);
    }

    function test_createPaidTicket() public {
        ExtraTicketData memory extraTicketData;
        vm.expectEmit(true, true, true, false, hostIt);
        emit TicketCreated(1, owner, extraTicketData);
        _createPaidTicket();
        uint56 ticketId = factoryFacet.ticketCount();
        TicketData memory ticketData = _getPaidTicketData();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        assertEq(fullTicketData.name, ticketData.name);
        assertEq(fullTicketData.symbol, "TICKET");
        assertEq(fullTicketData.uri, ticketData.uri);
        assertEq(fullTicketData.startTime, ticketData.startTime);
        assertEq(fullTicketData.purchaseStartTime, ticketData.purchaseStartTime);
        assertEq(fullTicketData.maxTickets, ticketData.maxTickets);
        assertEq(fullTicketData.isFree, ticketData.isFree);
        assertEq(fullTicketData.createdAt, _currentTime);
        assertEq(fullTicketData.updatedAt, 0);
    }

    function test_ticketCount() public {
        _createFreeTicket();
        _createFreeTicket();
        _createPaidTicket();
        assertEq(factoryFacet.ticketCount(), 3);
    }

    function test_ticketExists() public {
        _createFreeTicket();
        assertTrue(factoryFacet.ticketExists(1));
        assertFalse(factoryFacet.ticketExists(10000));
    }

    function test_allTicketData() public {
        _createFreeTicket();
        _createFreeTicket();
        _createPaidTicket();
        FullTicketData[] memory fullTicketDatas = factoryFacet.allTicketData();
        assertEq(fullTicketDatas.length, 3);
        assertEq(fullTicketDatas[0].id, 1);
        assertEq(fullTicketDatas[1].id, 2);
        assertEq(fullTicketDatas[2].id, 3);
    }

    function test_adminTicketData() public {
        _createFreeTicket();
        _createFreeTicket();
        vm.prank(alice);
        _createPaidTicket();
        FullTicketData[] memory ownerTicketDatas = factoryFacet.adminTicketData(owner);
        FullTicketData[] memory aliceTicketDatas = factoryFacet.adminTicketData(alice);
        assertEq(ownerTicketDatas.length, 2);
        assertEq(aliceTicketDatas.length, 1);
        assertEq(ownerTicketDatas[0].id, 1);
        assertEq(ownerTicketDatas[1].id, 2);
        assertEq(aliceTicketDatas[0].id, 3);
    }

    function test_adminTickets() public {
        _createFreeTicket();
        _createFreeTicket();
        vm.prank(alice);
        _createPaidTicket();
        uint56[] memory ownerTickets = factoryFacet.adminTickets(owner);
        uint56[] memory aliceTickets = factoryFacet.adminTickets(alice);
        assertEq(ownerTickets.length, 2);
        assertEq(aliceTickets.length, 1);
        assertEq(ownerTickets[0], 1);
        assertEq(ownerTickets[1], 2);
        assertEq(aliceTickets[0], 3);
    }

    function test_hostItTicketHash() public view {
        bytes32 hostItTicketHash = factoryFacet.hostItTicketHash();
        assertEq(hostItTicketHash, keccak256("host.it.ticket"));
    }

    function test_ticketHash() public view {
        uint56 ticketId = factoryFacet.ticketCount();
        bytes32 ticketHash = factoryFacet.ticketHash(ticketId);
        assertEq(ticketHash, keccak256(abi.encode(keccak256("host.it.ticket"), ticketId)));
    }

    function test_mainAdminRole() public view {
        uint56 ticketId = factoryFacet.ticketCount();
        uint256 mainAdminRole = factoryFacet.mainAdminRole(ticketId);
        assertEq(mainAdminRole, uint256(keccak256(abi.encode(keccak256("host.it.ticket.main.admin"), ticketId))));
    }

    function test_ticketAdminRole() public view {
        uint56 ticketId = factoryFacet.ticketCount();
        uint256 ticketAdminRole = factoryFacet.ticketAdminRole(ticketId);
        assertEq(ticketAdminRole, uint256(keccak256(abi.encode(keccak256("host.it.ticket.admin"), ticketId))));
    }
}
