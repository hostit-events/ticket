// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/CheckInLogs.sol";

contract CheckInTest is DeployedHostItTickets {
    function test_checkIn() public {
        (uint56 ticketId, uint40 tokenId) = _mintTicketFree();
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
        (uint56 ticketId,) = _mintTicketFree();
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
        (uint56 ticketId,) = _mintTicketFree();
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
}
