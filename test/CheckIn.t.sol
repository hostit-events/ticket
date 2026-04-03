// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FullTicketData} from "@ticket-storage/FactoryStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/CheckInLogs.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-errors/CheckInErrors.sol";

contract CheckInTest is DeployedHostItTickets {
    function test_checkIn() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        vm.expectEmit(true, true, true, true, hostIt);
        emit CheckedIn(ticketId, alice, tokenId);
        checkInFacet.checkIn(ticketId, alice, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 0, alice));
        vm.warp(block.timestamp + 1 days);
        vm.expectEmit(true, true, true, true, hostIt);
        emit CheckedIn(ticketId, alice, tokenId);
        checkInFacet.checkIn(ticketId, alice, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 1, alice));
    }

    function test_addTicketAdmins() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](2);
        admins[0] = bob;
        admins[1] = charlie;
        checkInFacet.addTicketAdmins(ticketId, admins);
        vm.warp(1 days + 1);
        vm.prank(bob);
        checkInFacet.checkIn(ticketId, alice, 1);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 0, alice));
        vm.warp(block.timestamp + 1 days);
        vm.prank(charlie);
        checkInFacet.checkIn(ticketId, alice, 1);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 1, alice));
    }

    function test_removeTicketAdmins() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = bob;
        checkInFacet.addTicketAdmins(ticketId, admins);
        vm.warp(1 days + 1);
        vm.prank(bob);
        checkInFacet.checkIn(ticketId, alice, 1);
        checkInFacet.removeTicketAdmins(ticketId, admins);
        vm.warp(block.timestamp + 1 days);
        vm.prank(bob);
        vm.expectRevert();
        checkInFacet.checkIn(ticketId, alice, 1);
    }

    // ======================================================================
    //                           FUZZ TESTS
    // ======================================================================

    function testFuzz_checkIn_validDay(uint256 dayOffset) public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        // Event runs from startTime to endTime (1 day duration in default data)
        uint256 eventDuration = ftd.endTime - ftd.startTime;
        dayOffset = bound(dayOffset, 0, eventDuration - 1);

        vm.warp(ftd.startTime + dayOffset);
        checkInFacet.checkIn(ticketId, alice, tokenId);

        uint8 expectedDay = uint8(dayOffset / 1 days);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, expectedDay, alice));
    }

    function testFuzz_checkIn_revertsBeforeStart(uint256 warpTo) public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        warpTo = bound(warpTo, block.timestamp, ftd.startTime - 1);
        vm.warp(warpTo);

        vm.expectRevert(TicketUsePeriodNotStarted.selector);
        checkInFacet.checkIn(ticketId, alice, tokenId);
    }

    function testFuzz_checkIn_revertsAfterEnd(uint256 extraTime) public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        extraTime = bound(extraTime, 1, 365 days);
        vm.warp(ftd.endTime + extraTime);

        vm.expectRevert(TicketUsePeriodHasEnded.selector);
        checkInFacet.checkIn(ticketId, alice, tokenId);
    }

    function testFuzz_addTicketAdmins(uint8 adminCount) public {
        adminCount = uint8(bound(adminCount, 1, 20));

        (uint64 ticketId,) = _mintTicketFree();

        address[] memory admins = new address[](adminCount);
        for (uint8 i; i < adminCount; ++i) {
            admins[i] = makeAddr(string(abi.encodePacked("admin", i)));
        }

        checkInFacet.addTicketAdmins(ticketId, admins);

        // Each admin can check in
        vm.warp(1 days + 1);
        vm.prank(admins[0]);
        checkInFacet.checkIn(ticketId, alice, 1);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
    }
}
