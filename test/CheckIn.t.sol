// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
import {FullTicketData} from "@ticket/libs/FactoryLib.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket/libs/CheckInLib.sol";

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
    //                        REVERT TESTS
    // ======================================================================

    function test_checkIn_revertsNotTicketOwner() public {
        (uint64 ticketId,) = _mintTicketFree();
        vm.warp(1 days + 1);
        vm.expectRevert(abi.encodeWithSelector(NotTicketOwner.selector, uint40(1)));
        checkInFacet.checkIn(ticketId, bob, 1);
    }

    function test_checkIn_revertsAlreadyCheckedInForDay() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        checkInFacet.checkIn(ticketId, alice, tokenId);
        vm.expectRevert(abi.encodeWithSelector(AlreadyCheckedInForDay.selector, uint8(0)));
        checkInFacet.checkIn(ticketId, alice, tokenId);
    }

    function test_addTicketAdmins_revertsNoAdmins() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](0);
        vm.expectRevert(NoAdmins.selector);
        checkInFacet.addTicketAdmins(ticketId, admins);
    }

    function test_addTicketAdmins_revertsAddressZero() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = address(0);
        vm.expectRevert(AddressZeroAdmin.selector);
        checkInFacet.addTicketAdmins(ticketId, admins);
    }

    function test_removeTicketAdmins_revertsNoAdmins() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](0);
        vm.expectRevert(NoAdmins.selector);
        checkInFacet.removeTicketAdmins(ticketId, admins);
    }

    function test_removeTicketAdmins_revertsAddressZero() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = address(0);
        vm.expectRevert(AddressZeroAdmin.selector);
        checkInFacet.removeTicketAdmins(ticketId, admins);
    }

    function test_addTicketAdmins_revertsNonMainAdmin() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = charlie;
        vm.prank(alice);
        vm.expectRevert();
        checkInFacet.addTicketAdmins(ticketId, admins);
    }

    function test_removeTicketAdmins_revertsNonMainAdmin() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = bob;
        checkInFacet.addTicketAdmins(ticketId, admins);
        vm.prank(alice);
        vm.expectRevert();
        checkInFacet.removeTicketAdmins(ticketId, admins);
    }

    function test_checkIn_revertsNonAdmin() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        vm.prank(alice);
        vm.expectRevert();
        checkInFacet.checkIn(ticketId, alice, tokenId);
    }

    function test_getCheckedIn() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        checkInFacet.checkIn(ticketId, alice, tokenId);
        address[] memory checkedIn = checkInFacet.getCheckedIn(ticketId);
        assertEq(checkedIn.length, 1);
        assertEq(checkedIn[0], alice);
    }

    function test_getCheckedInForDay() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        checkInFacet.checkIn(ticketId, alice, tokenId);
        address[] memory checkedIn = checkInFacet.getCheckedInForDay(ticketId, 0);
        assertEq(checkedIn.length, 1);
        assertEq(checkedIn[0], alice);
        // Day 1 should be empty
        address[] memory day1 = checkInFacet.getCheckedInForDay(ticketId, 1);
        assertEq(day1.length, 0);
    }

    function test_isCheckedIn_returnsFalseWhenNot() public {
        (uint64 ticketId,) = _mintTicketFree();
        assertFalse(checkInFacet.isCheckedIn(ticketId, alice));
        assertFalse(checkInFacet.isCheckedInForDay(ticketId, 0, alice));
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
