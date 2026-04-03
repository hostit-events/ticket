// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketCreated, TicketUpdated} from "@ticket-logs/FactoryLogs.sol";
import {ExtraTicketData, FullTicketData, TicketData} from "@ticket-storage/FactoryStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-errors/FactoryErrors.sol";

contract FactoryTest is DeployedHostItTickets {
    function test_createFreeTicket() public {
        ExtraTicketData memory extraTicketData;
        vm.expectEmit(true, true, true, false, hostIt);
        emit TicketCreated(1, owner, extraTicketData);
        _createFreeTicket();
        uint64 ticketId = factoryFacet.ticketCount();
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
        uint64 ticketId = factoryFacet.ticketCount();
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
        uint64 ticketId = factoryFacet.ticketCount();
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

    function test_updatePaidTicket() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        TicketData memory ticketData = _getPaidUpdatedTicketData();
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

    function test_adminTickets() public {
        _createFreeTicket();
        _createFreeTicket();
        vm.prank(alice);
        _createPaidTicket();
        uint64[] memory ownerTickets = factoryFacet.adminTickets(owner);
        uint64[] memory aliceTickets = factoryFacet.adminTickets(alice);
        assertEq(ownerTickets.length, 2);
        assertEq(aliceTickets.length, 1);
        assertEq(ownerTickets[0], 1);
        assertEq(ownerTickets[1], 2);
        assertEq(aliceTickets[0], 3);
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

    function test_hostItTicketHash() public view {
        bytes32 hostItTicketHash = factoryFacet.hostItTicketHash();
        assertEq(hostItTicketHash, keccak256("host.it.ticket"));
    }

    function test_ticketHash() public view {
        uint64 ticketId = factoryFacet.ticketCount();
        bytes32 ticketHash = factoryFacet.ticketHash(ticketId);
        assertEq(ticketHash, keccak256(abi.encode(keccak256("host.it.ticket"), ticketId)));
    }

    function test_mainAdminRole() public view {
        uint64 ticketId = factoryFacet.ticketCount();
        uint256 mainAdminRole = factoryFacet.mainAdminRole(ticketId);
        assertEq(mainAdminRole, uint256(keccak256(abi.encode(keccak256("host.it.ticket.main.admin"), ticketId))));
    }

    function test_ticketAdminRole() public view {
        uint64 ticketId = factoryFacet.ticketCount();
        uint256 ticketAdminRole = factoryFacet.ticketAdminRole(ticketId);
        assertEq(ticketAdminRole, uint256(keccak256(abi.encode(keccak256("host.it.ticket.admin"), ticketId))));
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 FUZZ TESTS
    //////////////////////////////////////////////////////////////////////////*//

    function testFuzz_createTicket_validTimes(uint48 startOffset, uint48 duration) public {
        startOffset = uint48(bound(startOffset, 2 days, 365 days));
        duration = uint48(bound(duration, 1 days, 365 days));

        uint48 startTime = uint48(block.timestamp) + startOffset;
        uint48 endTime = startTime + duration;
        uint48 purchaseStartTime = startTime - uint48(1 days);

        TicketData memory td = TicketData({
            startTime: startTime,
            endTime: endTime,
            purchaseStartTime: purchaseStartTime,
            maxTickets: type(uint40).max,
            maxTicketsPerUser: 0,
            isFree: true,
            isRefundable: false,
            name: "Fuzz Ticket",
            symbol: "",
            uri: "ipfs://fuzz"
        });

        factoryFacet.createTicket(td, _getZeroFeeType(), _getZeroFee());
        uint64 ticketId = factoryFacet.ticketCount();
        assertTrue(factoryFacet.ticketExists(ticketId));

        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        assertEq(ftd.startTime, startTime);
        assertEq(ftd.endTime, endTime);
        assertEq(ftd.purchaseStartTime, purchaseStartTime);
    }

    function testFuzz_createTicket_revertsStartTimeInPast(uint48 offset) public {
        offset = uint48(bound(offset, 1, uint48(block.timestamp)));
        uint48 startTime = uint48(block.timestamp) - offset;

        TicketData memory td = TicketData({
            startTime: startTime,
            endTime: startTime + uint48(2 days),
            purchaseStartTime: 0,
            maxTickets: type(uint40).max,
            maxTicketsPerUser: 0,
            isFree: true,
            isRefundable: false,
            name: "Bad Ticket",
            symbol: "",
            uri: "ipfs://bad"
        });

        vm.expectRevert(StartTimeShouldBeAhead.selector);
        factoryFacet.createTicket(td, _getZeroFeeType(), _getZeroFee());
    }

    function testFuzz_createTicket_revertsEndTimeTooClose(uint48 gap) public {
        gap = uint48(bound(gap, 0, 1 days - 1));
        uint48 startTime = uint48(block.timestamp + 2 days);
        uint48 endTime = startTime + gap;

        TicketData memory td = TicketData({
            startTime: startTime,
            endTime: endTime,
            purchaseStartTime: uint48(block.timestamp),
            maxTickets: type(uint40).max,
            maxTicketsPerUser: 0,
            isFree: true,
            isRefundable: false,
            name: "Bad Ticket",
            symbol: "",
            uri: "ipfs://bad"
        });

        vm.expectRevert(EndTimeShouldBeOneDayAfterStartTime.selector);
        factoryFacet.createTicket(td, _getZeroFeeType(), _getZeroFee());
    }

    function testFuzz_ticketHash(uint64 ticketId) public view {
        bytes32 ticketHash = factoryFacet.ticketHash(ticketId);
        assertEq(ticketHash, keccak256(abi.encode(keccak256("host.it.ticket"), ticketId)));
    }

    function testFuzz_mainAdminRole(uint64 ticketId) public view {
        uint256 mainAdminRole = factoryFacet.mainAdminRole(ticketId);
        assertEq(mainAdminRole, uint256(keccak256(abi.encode(keccak256("host.it.ticket.main.admin"), ticketId))));
    }

    function testFuzz_ticketAdminRole(uint64 ticketId) public view {
        uint256 ticketAdminRole = factoryFacet.ticketAdminRole(ticketId);
        assertEq(ticketAdminRole, uint256(keccak256(abi.encode(keccak256("host.it.ticket.admin"), ticketId))));
    }

    function testFuzz_ticketExists(uint64 ticketId) public {
        _createFreeTicket();
        if (ticketId == 1) {
            assertTrue(factoryFacet.ticketExists(ticketId));
        } else {
            assertFalse(factoryFacet.ticketExists(ticketId));
        }
    }
}
