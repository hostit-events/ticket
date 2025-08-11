// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Ticket} from "@host-it/Ticket.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

    function test_ticketInitialize() public view {
        vm.assertEq(ticketClone.owner(), owner);
        vm.assertEq(ticketClone.name(), "Test Ticket");
        vm.assertEq(ticketClone.baseURI(), "ipfs://");
    }

    function test_updateName() public {
        ticketClone.updateName("Updated Ticket");
        vm.assertEq(ticketClone.name(), "Updated Ticket");
    }

    function test_updateSymbol() public {
        ticketClone.updateSymbol("NEW");
        vm.assertEq(ticketClone.symbol(), "NEW");
    }

    function test_updateURI() public {
        ticketClone.updateURI("ipfs://new-uri");
        vm.assertEq(ticketClone.baseURI(), "ipfs://new-uri");
    }

    function test_mint() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.assertEq(ticketClone.totalSupply(), tokenId);
        vm.assertEq(ticketClone.ownerOf(tokenId), alice);
        vm.assertEq(ticketClone.balanceOf(alice), 1);
    }

    function test_pause() public {
        ticketClone.pause();
        vm.assertTrue(ticketClone.paused());
    }

    function test_unpause() public {
        ticketClone.pause();
        ticketClone.unpause();
        vm.assertFalse(ticketClone.paused());
    }

    function test_transferFrom() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        ticketClone.transferFrom(alice, owner, tokenId);
        vm.assertEq(ticketClone.ownerOf(tokenId), owner);
        vm.assertEq(ticketClone.balanceOf(owner), 1);
    }

    function test_safeTransferFrom() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        ticketClone.safeTransferFrom(alice, bob, tokenId);
        vm.assertEq(ticketClone.ownerOf(tokenId), bob);
        vm.assertEq(ticketClone.balanceOf(bob), 1);
    }

    function test_tokenURI() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.assertEq(ticketClone.tokenURI(tokenId), ticketClone.baseURI());
    }

    function test_mintWhilePaused() public {
        ticketClone.pause();
        uint256 tokenId = ticketClone.mint(alice);
        vm.assertEq(ticketClone.totalSupply(), tokenId);
        vm.assertEq(ticketClone.ownerOf(tokenId), alice);
        vm.assertEq(ticketClone.balanceOf(alice), 1);
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
}
