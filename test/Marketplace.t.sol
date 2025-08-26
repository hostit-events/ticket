// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {FullTicketData} from "@ticket-storage/FactoryStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/MarketplaceLogs.sol";

contract MarketplaceTest is DeployedHostItTickets {
    function test_mintFreeTicket() public {
        vm.prank(alice);
        (uint56 ticketId, uint40 tokenId) = _mintTicketFree();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
    }

    function test_mintPaidTicketETH() public {
        (uint56 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee) = _mintTicketETH();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
    }

    function test_mintPaidTicketUSDT() public {
        (uint56 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee,) = _mintTicketUSDT();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), hostItFee);
    }

    function test_mintPaidTicketUSDC() public {
        (uint56 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee,) = _mintTicketUSDC();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), hostItFee);
    }

    function test_setTicketFees() public {
        _createFreeTicket();
        uint56 ticketId = factoryFacet.ticketCount();
        marketplaceFacet.setTicketFees(ticketId, _getFeeTypes(), _getFees());
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.ETH), _getFees()[0]);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.USDT), _getFees()[1]);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.USDC), _getFees()[2]);
    }

    function test_withdrawTicketBalanceETH() public {
        (uint56 ticketId,, uint256 ethFee,) = _mintTicketETH();
        // Check platform balances before withdraw
        // Withdraw
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.ETH, ethFee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.ETH, withdrawer);
        // Check platform balances after withdraw
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        // Check vault balances after withdraw
        assertEq(withdrawer.balance, ethFee);
    }

    function test_withdrawTicketBalanceUSDT() public {
        (uint56 ticketId,, uint256 usdtFee,, ERC20Mock usdt) = _mintTicketUSDT();
        // Check platform balances before withdraw
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), usdtFee);
        // Withdraw
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.USDT, usdtFee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.USDT, withdrawer);
        // Check platform balances after withdraw
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), 0);
        // Check owner balances after withdraw
        assertEq(usdt.balanceOf(withdrawer), usdtFee);
    }

    function test_withdrawTicketBalanceUSDC() public {
        (uint56 ticketId,, uint256 usdcFee,, ERC20Mock usdc) = _mintTicketUSDC();
        // Check platform balances before withdraw
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), usdcFee);
        // Withdraw
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.USDC, usdcFee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.USDC, withdrawer);
        // Check platform balances after withdraw
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), 0);
        // Check owner balances after withdraw
        assertEq(usdc.balanceOf(withdrawer), usdcFee);
    }

    function test_withdrawHostItBalanceETH() public {
        (,,, uint256 hostItFee) = _mintTicketETH();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.ETH, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.ETH, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), 0);
        assertEq(withdrawer.balance, hostItFee);
    }

    function test_withdrawHostItBalanceUSDT() public {
        (,,, uint256 hostItFee, ERC20Mock usdt) = _mintTicketUSDT();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.USDT, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.USDT, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), 0);
        assertEq(usdt.balanceOf(withdrawer), hostItFee);
    }

    function test_withdrawHostItBalanceUSDC() public {
        (,,, uint256 hostItFee, ERC20Mock usdc) = _mintTicketUSDC();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.USDC, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.USDC, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), 0);
        assertEq(usdc.balanceOf(withdrawer), hostItFee);
    }
}
