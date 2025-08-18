// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketData, FullTicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";

contract FactoryTest is DeployedHostItTickets {
    function setUp() public override {
        super.setUp();
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
    }

    function test_createTicketNoFee() public view {
        uint56 ticketId = factoryFacet.ticketCount();
        TicketData memory ticketData = _getTicketData();
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

    function test_updateTicketNoFee() public {
        uint56 ticketId = factoryFacet.ticketCount();
        TicketData memory ticketData = _getUpdatedTicketData();
        vm.warp(10000);
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

    function test_ticketCount() public {
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
        factoryFacet.createTicket(_getUpdatedTicketData(), _getZeroFeeTypes(), _getZeroFees());
        assertEq(factoryFacet.ticketCount(), 3);
    }

    function test_ticketExists() public view {
        assertTrue(factoryFacet.ticketExists(1));
        assertFalse(factoryFacet.ticketExists(10000));
    }

    function test_allTicketData() public {
        factoryFacet.createTicket(_getUpdatedTicketData(), _getZeroFeeTypes(), _getZeroFees());
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
        FullTicketData[] memory fullTicketDatas = factoryFacet.allTicketData();
        assertEq(fullTicketDatas.length, 3);
        assertEq(fullTicketDatas[0].id, 1);
        assertEq(fullTicketDatas[1].id, 2);
        assertEq(fullTicketDatas[2].id, 3);
    }

    function test_adminTicketData() public {
        factoryFacet.createTicket(_getUpdatedTicketData(), _getZeroFeeTypes(), _getZeroFees());
        vm.prank(alice);
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
        FullTicketData[] memory ownerTicketDatas = factoryFacet.adminTicketData(owner);
        FullTicketData[] memory aliceTicketDatas = factoryFacet.adminTicketData(alice);
        assertEq(ownerTicketDatas.length, 2);
        assertEq(aliceTicketDatas.length, 1);
        assertEq(ownerTicketDatas[0].id, 1);
        assertEq(ownerTicketDatas[1].id, 2);
        assertEq(aliceTicketDatas[0].id, 3);
    }

    function test_adminTickets() public {
        factoryFacet.createTicket(_getUpdatedTicketData(), _getZeroFeeTypes(), _getZeroFees());
        vm.prank(alice);
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
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
