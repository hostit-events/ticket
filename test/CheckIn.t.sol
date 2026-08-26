// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
import {AddressZeroAdmin, FullTicketData, NoAdmins} from "@ticket/libs/FactoryLib.sol";
import {FeeType} from "@ticket/libs/MarketplaceLib.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket/libs/CheckInLib.sol";

contract CheckInTest is DeployedHostItTickets {
    function test_checkIn() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        vm.expectEmit(true, true, true, true, hostIt);
        emit CheckedIn(ticketId, alice, 0, tokenId);
        checkInFacet.checkIn(ticketId, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 0, alice));
        vm.warp(block.timestamp + 1 days);
        vm.expectEmit(true, true, true, true, hostIt);
        emit CheckedIn(ticketId, alice, 1, tokenId);
        checkInFacet.checkIn(ticketId, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 1, alice));
    }

    function test_addTicketAdmins() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        address[] memory admins = new address[](2);
        admins[0] = bob;
        admins[1] = charlie;
        factoryFacet.addTicketAdmins(ticketId, admins);
        vm.warp(1 days + 1);
        vm.prank(bob);
        checkInFacet.checkIn(ticketId, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 0, alice));
        vm.warp(block.timestamp + 1 days);
        vm.prank(charlie);
        checkInFacet.checkIn(ticketId, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 1, alice));
    }

    function test_removeTicketAdmins() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = bob;
        factoryFacet.addTicketAdmins(ticketId, admins);
        vm.warp(1 days + 1);
        vm.prank(bob);
        checkInFacet.checkIn(ticketId, tokenId);
        factoryFacet.removeTicketAdmins(ticketId, admins);
        vm.warp(block.timestamp + 1 days);
        vm.prank(bob);
        vm.expectRevert();
        checkInFacet.checkIn(ticketId, tokenId);
    }

    // ======================================================================
    //                        REVERT TESTS
    // ======================================================================

    function test_checkIn_revertsNonexistentToken() public {
        (uint64 ticketId,) = _mintTicketFree();
        vm.warp(1 days + 1);
        vm.expectRevert();
        checkInFacet.checkIn(ticketId, 999);
    }

    function test_checkIn_revertsAlreadyCheckedInForDay() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        checkInFacet.checkIn(ticketId, tokenId);
        vm.expectRevert(abi.encodeWithSelector(AlreadyCheckedInForDay.selector, uint8(0)));
        checkInFacet.checkIn(ticketId, tokenId);
    }

    function test_addTicketAdmins_revertsNoAdmins() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](0);
        vm.expectRevert(NoAdmins.selector);
        factoryFacet.addTicketAdmins(ticketId, admins);
    }

    function test_addTicketAdmins_revertsAddressZero() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = address(0);
        vm.expectRevert(AddressZeroAdmin.selector);
        factoryFacet.addTicketAdmins(ticketId, admins);
    }

    function test_removeTicketAdmins_revertsNoAdmins() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](0);
        vm.expectRevert(NoAdmins.selector);
        factoryFacet.removeTicketAdmins(ticketId, admins);
    }

    function test_removeTicketAdmins_revertsAddressZero() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = address(0);
        vm.expectRevert(AddressZeroAdmin.selector);
        factoryFacet.removeTicketAdmins(ticketId, admins);
    }

    function test_addTicketAdmins_revertsNonMainAdmin() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = charlie;
        vm.prank(alice);
        vm.expectRevert();
        factoryFacet.addTicketAdmins(ticketId, admins);
    }

    function test_removeTicketAdmins_revertsNonMainAdmin() public {
        (uint64 ticketId,) = _mintTicketFree();
        address[] memory admins = new address[](1);
        admins[0] = bob;
        factoryFacet.addTicketAdmins(ticketId, admins);
        vm.prank(alice);
        vm.expectRevert();
        factoryFacet.removeTicketAdmins(ticketId, admins);
    }

    function test_checkIn_revertsNonAdmin() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        vm.prank(alice);
        vm.expectRevert();
        checkInFacet.checkIn(ticketId, tokenId);
    }

    function test_getCheckedIn() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        checkInFacet.checkIn(ticketId, tokenId);
        address[] memory checkedIn = checkInFacet.getCheckedIn(ticketId);
        assertEq(checkedIn.length, 1);
        assertEq(checkedIn[0], alice);
    }

    function test_getCheckedInForDay() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        checkInFacet.checkIn(ticketId, tokenId);
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
    //                          BATCH TESTS
    // ======================================================================

    function test_checkInBatch_happyPath() public {
        (uint64 ticketId, uint40 aliceToken) = _mintTicketFree();
        uint40 bobToken = marketplaceFacet.mintTicket(ticketId, FeeType.NONE, bob);

        vm.warp(1 days + 1);

        uint40[] memory tokenIds = new uint40[](2);
        tokenIds[0] = aliceToken;
        tokenIds[1] = bobToken;
        checkInFacet.checkInBatch(ticketId, tokenIds);

        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
        assertTrue(checkInFacet.isCheckedIn(ticketId, bob));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 0, alice));
        assertTrue(checkInFacet.isCheckedInForDay(ticketId, 0, bob));
    }

    function test_checkInBatch_revertsEmpty() public {
        (uint64 ticketId,) = _mintTicketFree();
        vm.warp(1 days + 1);
        uint40[] memory tokenIds = new uint40[](0);
        vm.expectRevert(EmptyBatch.selector);
        checkInFacet.checkInBatch(ticketId, tokenIds);
    }

    function test_checkInBatch_revertsNonAdmin() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        vm.warp(1 days + 1);
        uint40[] memory tokenIds = new uint40[](1);
        tokenIds[0] = tokenId;
        vm.prank(alice);
        vm.expectRevert();
        checkInFacet.checkInBatch(ticketId, tokenIds);
    }

    function test_checkInBatch_revertsDuplicateOwnerSameDay() public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();

        vm.warp(1 days + 1);

        // Same tokenId twice -> same owner -> day set rejects second add
        uint40[] memory tokenIds = new uint40[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId;
        vm.expectRevert(abi.encodeWithSelector(AlreadyCheckedInForDay.selector, uint8(0)));
        checkInFacet.checkInBatch(ticketId, tokenIds);
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
        checkInFacet.checkIn(ticketId, tokenId);

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
        checkInFacet.checkIn(ticketId, tokenId);
    }

    function testFuzz_checkIn_revertsAfterEnd(uint256 extraTime) public {
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        extraTime = bound(extraTime, 1, 365 days);
        vm.warp(ftd.endTime + extraTime);

        vm.expectRevert(TicketUsePeriodHasEnded.selector);
        checkInFacet.checkIn(ticketId, tokenId);
    }

    function testFuzz_addTicketAdmins(uint8 adminCount) public {
        adminCount = uint8(bound(adminCount, 1, 20));

        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();

        address[] memory admins = new address[](adminCount);
        for (uint8 i; i < adminCount; ++i) {
            admins[i] = makeAddr(string(abi.encodePacked("admin", i)));
        }

        factoryFacet.addTicketAdmins(ticketId, admins);

        // Each admin can check in
        vm.warp(1 days + 1);
        vm.prank(admins[0]);
        checkInFacet.checkIn(ticketId, tokenId);
        assertTrue(checkInFacet.isCheckedIn(ticketId, alice));
    }
}
