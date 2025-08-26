// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Ticket} from "@ticket/Ticket.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
        vm.expectEmit(true, true, true, true);
        emit Initializable.Initialized(1);
        ticketClone.initialize(owner, "Test Ticket", "ipfs://");
    }

    function test_revertTicketProxyInit() public {
        vm.expectRevert();
        ticketImpl.initialize(owner, "Test Ticket", "ipfs://");
    }

    function test_ticketInitialize() public view {
        assertEq(ticketClone.owner(), owner);
        assertEq(ticketClone.name(), "Test Ticket");
        assertEq(ticketClone.baseURI(), "ipfs://");
    }

    function test_updateName() public {
        vm.expectEmit(true, true, true, true);
        emit ITicket.NameUpdated("Updated Ticket");
        ticketClone.updateName("Updated Ticket");
        assertEq(ticketClone.name(), "Updated Ticket");
    }

    function test_updateSymbol() public {
        vm.expectEmit(true, true, true, true);
        emit ITicket.SymbolUpdated("NEW");
        ticketClone.updateSymbol("NEW");
        assertEq(ticketClone.symbol(), "NEW");
    }

    function test_updateURI() public {
        vm.expectEmit(true, true, true, true);
        emit ITicket.BaseURIUpdated("ipfs://new-uri");
        ticketClone.updateURI("ipfs://new-uri");
        assertEq(ticketClone.baseURI(), "ipfs://new-uri");
    }

    function test_mint() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), alice, 1);
        uint256 tokenId = ticketClone.mint(alice);
        assertEq(ticketClone.totalSupply(), tokenId);
        assertEq(ticketClone.ownerOf(tokenId), alice);
        assertEq(ticketClone.balanceOf(alice), 1);
    }

    function test_pause() public {
        vm.expectEmit(true, true, true, true);
        emit Pausable.Paused(owner);
        ticketClone.pause();
        assertTrue(ticketClone.paused());
    }

    function test_unpause() public {
        ticketClone.pause();
        vm.expectEmit(true, true, true, true);
        emit Pausable.Unpaused(owner);
        ticketClone.unpause();
        assertFalse(ticketClone.paused());
    }

    function test_transferFrom() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(alice, owner, 1);
        ticketClone.transferFrom(alice, owner, tokenId);
        assertEq(ticketClone.ownerOf(tokenId), owner);
        assertEq(ticketClone.balanceOf(owner), 1);
    }

    function test_safeTransferFrom() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(alice, bob, 1);
        ticketClone.safeTransferFrom(alice, bob, tokenId);
        assertEq(ticketClone.ownerOf(tokenId), bob);
        assertEq(ticketClone.balanceOf(bob), 1);
    }

    function test_tokenURI() public {
        uint256 tokenId = ticketClone.mint(alice);
        assertEq(ticketClone.tokenURI(tokenId), ticketClone.baseURI());
    }

    function test_mintWhilePaused() public {
        vm.expectEmit(true, true, true, true);
        emit Pausable.Paused(owner);
        ticketClone.pause();
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), alice, 1);
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
