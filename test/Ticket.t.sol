// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Ticket} from "@ticket/Ticket.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract TicketTest is Test {
    using Clones for address;

    Ticket public ticketImpl;
    Ticket public ticketClone;

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        ticketImpl = new Ticket();
        ticketClone = Ticket(address(ticketImpl).clone());
        ticketClone.initialize(owner, "Test Ticket", "ipfs://");
    }

    // TODO: disable ticket upgrade
    // function test_revertTicketImplInit() public {
    //     vm.expectRevert();
    //     ticketImpl.initialize(owner, "Test Ticket", "ipfs://");
    // }

    function test_ticketInitialize() public view {
        assertEq(ticketClone.owner(), owner);
        assertEq(ticketClone.name(), "Test Ticket");
        assertEq(ticketClone.baseURI(), "ipfs://");
    }

    function test_updateName() public {
        ticketClone.updateName("Updated Ticket");
        assertEq(ticketClone.name(), "Updated Ticket");
    }

    function test_updateSymbol() public {
        ticketClone.updateSymbol("NEW");
        assertEq(ticketClone.symbol(), "NEW");
    }

    function test_updateURI() public {
        ticketClone.updateURI("ipfs://new-uri");
        assertEq(ticketClone.baseURI(), "ipfs://new-uri");
    }

    function test_mint() public {
        uint256 tokenId = ticketClone.mint(alice);
        assertEq(ticketClone.totalSupply(), tokenId);
        assertEq(ticketClone.ownerOf(tokenId), alice);
        assertEq(ticketClone.balanceOf(alice), 1);
    }

    function test_pause() public {
        ticketClone.pause();
        assertTrue(ticketClone.paused());
    }

    function test_unpause() public {
        ticketClone.pause();
        ticketClone.unpause();
        assertFalse(ticketClone.paused());
    }

    function test_transferFrom() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        ticketClone.transferFrom(alice, owner, tokenId);
        assertEq(ticketClone.ownerOf(tokenId), owner);
        assertEq(ticketClone.balanceOf(owner), 1);
    }

    function test_safeTransferFrom() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        ticketClone.safeTransferFrom(alice, bob, tokenId);
        assertEq(ticketClone.ownerOf(tokenId), bob);
        assertEq(ticketClone.balanceOf(bob), 1);
    }

    function test_tokenURI() public {
        uint256 tokenId = ticketClone.mint(alice);
        assertEq(ticketClone.tokenURI(tokenId), ticketClone.baseURI());
    }

    function test_mintWhilePaused() public {
        ticketClone.pause();
        uint256 tokenId = ticketClone.mint(alice);
        assertEq(ticketClone.totalSupply(), tokenId);
        assertEq(ticketClone.ownerOf(tokenId), alice);
        assertEq(ticketClone.balanceOf(alice), 1);
    }

    function test_revertTransferFromWhilePaused() public {
        ticketClone.pause();
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.transferFrom(alice, owner, tokenId);
    }

    function test_revertSafeTransferFromWhilePaused() public {
        ticketClone.pause();
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.safeTransferFrom(alice, bob, tokenId);
    }

    function test_otherClonesDontClash() public {
        Ticket ticketClone2 = Ticket(address(ticketImpl).clone());
        ticketClone2.initialize(alice, "Test Ticket 2", "ipfs://2");
        assertEq(ticketClone2.owner(), alice);
        assertEq(ticketClone2.name(), "Test Ticket 2");
        assertEq(ticketClone2.baseURI(), "ipfs://2");
        assertNotEq(address(ticketClone), address(ticketClone2));
    }
}
