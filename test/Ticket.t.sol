// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {Ticket} from "@ticket/libs/Ticket.sol";
import {Test} from "forge-std/Test.sol";

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
        ticketClone.initialize(owner, "Test Ticket", "", "ipfs://");
    }

    function test_revertTicketProxyInit() public {
        vm.expectRevert();
        ticketImpl.initialize(owner, "Test Ticket", "", "ipfs://");
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

    /// forge-lint: disable-next-item(erc20-unchecked-transfer)
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

    // ======================================================================
    //                        USE-TICKET LIFECYCLE
    // ======================================================================

    function test_useTicket() public {
        uint256 tokenId = ticketClone.mint(alice);
        assertFalse(ticketClone.isUsed(tokenId));
        vm.expectEmit(true, true, true, true);
        emit ITicket.TicketUsed(tokenId);
        ticketClone.useTicket(tokenId);
        assertTrue(ticketClone.isUsed(tokenId));
    }

    function test_useTicket_revertsNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, uint256(999)));
        ticketClone.useTicket(999);
    }

    function test_useTicket_revertsNonOwner() public {
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.useTicket(tokenId);
    }

    /// forge-lint: disable-next-item(erc20-unchecked-transfer)
    function test_transferFrom_revertsAfterUse() public {
        uint256 tokenId = ticketClone.mint(alice);
        ticketClone.useTicket(tokenId);
        vm.prank(alice);
        vm.expectRevert(ITicket.TicketAlreadyUsed.selector);
        ticketClone.transferFrom(alice, bob, tokenId);
    }

    function test_safeTransferFrom_revertsAfterUse() public {
        uint256 tokenId = ticketClone.mint(alice);
        ticketClone.useTicket(tokenId);
        vm.prank(alice);
        vm.expectRevert(ITicket.TicketAlreadyUsed.selector);
        ticketClone.safeTransferFrom(alice, bob, tokenId);
    }

    function test_isUsed_falseBeforeUse() public {
        uint256 tokenId = ticketClone.mint(alice);
        assertFalse(ticketClone.isUsed(tokenId));
    }

    function test_otherClonesDontClash() public {
        Ticket ticketClone2 = Ticket(address(ticketImpl).clone());
        ticketClone2.initialize(alice, "Test Ticket 2", "", "ipfs://2");
        assertEq(ticketClone2.owner(), alice);
        assertEq(ticketClone2.name(), "Test Ticket 2");
        assertEq(ticketClone2.baseURI(), "ipfs://2");
        assertNotEq(address(ticketClone), address(ticketClone2));
    }

    // ======================================================================
    //                        COVERAGE TESTS
    // ======================================================================

    function test_tokenURI_revertsNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, uint256(999)));
        ticketClone.tokenURI(999);
    }

    function test_supportsInterface_ERC721() public view {
        assertTrue(ticketClone.supportsInterface(type(IERC721).interfaceId));
    }

    function test_supportsInterface_ERC721Enumerable() public view {
        assertTrue(ticketClone.supportsInterface(type(IERC721Enumerable).interfaceId));
    }

    function test_supportsInterface_ERC2981() public view {
        assertTrue(ticketClone.supportsInterface(type(IERC2981).interfaceId));
    }

    function test_supportsInterface_ERC165() public view {
        assertTrue(ticketClone.supportsInterface(type(IERC165).interfaceId));
    }

    function test_supportsInterface_invalid() public view {
        assertFalse(ticketClone.supportsInterface(0xffffffff));
    }

    function test_royaltyInfo() public {
        uint256 tokenId = ticketClone.mint(alice);
        (address receiver, uint256 royalty) = ticketClone.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, owner);
        assertEq(royalty, 500); // 5% of 10_000
    }

    function test_defaultSymbol() public view {
        assertEq(ticketClone.symbol(), "TICKET");
    }

    function test_initializeWithCustomSymbol() public {
        Ticket clone2 = Ticket(address(ticketImpl).clone());
        clone2.initialize(owner, "Test", "CUSTOM", "ipfs://");
        assertEq(clone2.symbol(), "CUSTOM");
    }

    function test_revertDoubleInitialize() public {
        vm.expectRevert();
        ticketClone.initialize(owner, "Again", "", "ipfs://");
    }

    function test_mintRevertsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.mint(alice);
    }

    function test_updateNameRevertsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.updateName("Hack");
    }

    function test_updateSymbolRevertsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.updateSymbol("HACK");
    }

    function test_updateURIRevertsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        ticketClone.updateURI("ipfs://hack");
    }

    function test_totalSupplyAndTokenByIndex() public {
        ticketClone.mint(alice);
        ticketClone.mint(bob);
        assertEq(ticketClone.totalSupply(), 2);
        assertEq(ticketClone.tokenByIndex(0), 1);
        assertEq(ticketClone.tokenByIndex(1), 2);
    }

    function test_tokenOfOwnerByIndex() public {
        ticketClone.mint(alice);
        ticketClone.mint(alice);
        assertEq(ticketClone.tokenOfOwnerByIndex(alice, 0), 1);
        assertEq(ticketClone.tokenOfOwnerByIndex(alice, 1), 2);
    }

    // ======================================================================
    //                           FUZZ TESTS
    // ======================================================================

    function testFuzz_mint(uint8 count) public {
        count = uint8(bound(count, 1, 50));
        for (uint8 i; i < count; ++i) {
            ticketClone.mint(alice);
        }
        assertEq(ticketClone.totalSupply(), count);
        assertEq(ticketClone.balanceOf(alice), count);
    }

    function testFuzz_updateName(string calldata name) public {
        vm.assume(bytes(name).length > 0);
        ticketClone.updateName(name);
        assertEq(ticketClone.name(), name);
    }

    function testFuzz_updateSymbol(string calldata symbol) public {
        ticketClone.updateSymbol(symbol);
        assertEq(ticketClone.symbol(), symbol);
    }

    function testFuzz_updateURI(string calldata uri) public {
        ticketClone.updateURI(uri);
        assertEq(ticketClone.baseURI(), uri);
    }

    /// forge-lint: disable-next-item(erc20-unchecked-transfer)
    function testFuzz_transferBetweenAddresses(address to) public {
        vm.assume(to != address(0) && to.code.length == 0 && to != alice);
        uint256 tokenId = ticketClone.mint(alice);
        vm.prank(alice);
        ticketClone.transferFrom(alice, to, tokenId);
        assertEq(ticketClone.ownerOf(tokenId), to);
        assertEq(ticketClone.balanceOf(to), 1);
        assertEq(ticketClone.balanceOf(alice), 0);
    }

    function testFuzz_useTicket_blocksTransfer(address to) public {
        vm.assume(to != address(0) && to.code.length == 0 && to != alice);
        uint256 tokenId = ticketClone.mint(alice);
        ticketClone.useTicket(tokenId);
        vm.prank(alice);
        vm.expectRevert(ITicket.TicketAlreadyUsed.selector);
        ticketClone.safeTransferFrom(alice, to, tokenId);
    }
}
