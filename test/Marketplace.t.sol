// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {FullTicketData, TicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/MarketplaceLogs.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-errors/MarketplaceErrors.sol";

contract MarketplaceTest is DeployedHostItTickets, ERC721Holder {
    // ======================================================================
    //                        FREE TICKET MINTING
    // ======================================================================

    function test_mintFreeTicket() public {
        vm.prank(alice);
        (uint64 ticketId, uint40 tokenId) = _mintTicketFree();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
    }

    function test_mintFreeTicket_noBalanceChanges() public {
        vm.prank(alice);
        (uint64 ticketId,) = _mintTicketFree();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), 0);
    }

    // ======================================================================
    //                    NON-REFUNDABLE DIRECT PAYMENT: ETH
    // ======================================================================

    function test_directPayment_ETH_organizerReceivesFee() public {
        uint256 ownerBalanceBefore = owner.balance;
        (,, uint256 fee,) = _mintTicketETH();
        assertEq(owner.balance - ownerBalanceBefore, fee);
    }

    function test_directPayment_ETH_buyerSpendsFullAmount() public {
        _mintTicketETH();
        assertEq(alice.balance, 0);
    }

    function test_directPayment_ETH_hostItFeeAccumulated() public {
        (,,, uint256 hostItFee) = _mintTicketETH();
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
    }

    function test_directPayment_ETH_noTicketBalanceEscrowed() public {
        (uint64 ticketId,,,) = _mintTicketETH();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
    }

    function test_directPayment_ETH_ticketMintedToBuyer() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETH();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
    }

    function test_directPayment_ETH_contractHoldsOnlyHostItFee() public {
        uint256 contractBalanceBefore = hostIt.balance;
        (,,, uint256 hostItFee) = _mintTicketETH();
        assertEq(hostIt.balance - contractBalanceBefore, hostItFee);
    }

    function test_directPayment_ETH_emitsTicketMinted() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);
        hoax(alice, totalFee);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId, FeeType.ETH, totalFee, 1);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);
    }

    function test_directPayment_ETH_multipleBuyersAccumulateHostItFees() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);

        hoax(bob, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, bob);

        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee * 2);
    }

    function test_directPayment_ETH_multipleBuyersPayOrganizer() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (uint256 fee,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        uint256 ownerBalanceBefore = owner.balance;

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);

        hoax(bob, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, bob);

        assertEq(owner.balance - ownerBalanceBefore, fee * 2);
    }

    function test_directPayment_ETH_revertsInsufficientValue() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);
        hoax(alice, totalFee);
        vm.expectRevert(abi.encodeWithSelector(TicketPurchaseFailed.selector, FeeType.ETH, totalFee));
        marketplaceFacet.mintTicket{value: totalFee - 1}(ticketId, FeeType.ETH, alice);
    }

    // ======================================================================
    //                   NON-REFUNDABLE DIRECT PAYMENT: USDT
    // ======================================================================

    function test_directPayment_USDT_organizerReceivesFee() public {
        (,, uint256 fee,,) = _mintTicketUSDT();
        ERC20Mock usdt = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDT));
        assertEq(usdt.balanceOf(owner), fee);
    }

    function test_directPayment_USDT_hostItFeeAccumulated() public {
        (,,, uint256 hostItFee,) = _mintTicketUSDT();
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), hostItFee);
    }

    function test_directPayment_USDT_noTicketBalanceEscrowed() public {
        (uint64 ticketId,,,,) = _mintTicketUSDT();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), 0);
    }

    function test_directPayment_USDT_contractHoldsHostItFee() public {
        (,,, uint256 hostItFee, ERC20Mock usdt) = _mintTicketUSDT();
        assertEq(usdt.balanceOf(hostIt), hostItFee);
    }

    function test_directPayment_USDT_buyerBalanceZero() public {
        (,,,, ERC20Mock usdt) = _mintTicketUSDT();
        assertEq(usdt.balanceOf(alice), 0);
    }

    function test_directPayment_USDT_ticketMintedToBuyer() public {
        (uint64 ticketId, uint40 tokenId,,,) = _mintTicketUSDT();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
    }

    // ======================================================================
    //                   NON-REFUNDABLE DIRECT PAYMENT: USDC
    // ======================================================================

    function test_directPayment_USDC_organizerReceivesFee() public {
        (,, uint256 fee,,) = _mintTicketUSDC();
        ERC20Mock usdc = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDC));
        assertEq(usdc.balanceOf(owner), fee);
    }

    function test_directPayment_USDC_hostItFeeAccumulated() public {
        (,,, uint256 hostItFee,) = _mintTicketUSDC();
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), hostItFee);
    }

    function test_directPayment_USDC_noTicketBalanceEscrowed() public {
        (uint64 ticketId,,,,) = _mintTicketUSDC();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), 0);
    }

    function test_directPayment_USDC_contractHoldsHostItFee() public {
        (,,, uint256 hostItFee, ERC20Mock usdc) = _mintTicketUSDC();
        assertEq(usdc.balanceOf(hostIt), hostItFee);
    }

    function test_directPayment_USDC_ticketMintedToBuyer() public {
        (uint64 ticketId, uint40 tokenId,,,) = _mintTicketUSDC();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
    }

    // ======================================================================
    //               NON-REFUNDABLE: TOKEN REVERT CASES
    // ======================================================================

    function test_directPayment_USDT_revertsInsufficientBalance() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.USDT);
        ERC20Mock usdt = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDT));
        // Mint just under totalFee so balance check fails on the second _payWithToken call (hostItFee)
        usdt.mint(alice, totalFee - 1);
        vm.prank(alice);
        usdt.approve(address(marketplaceFacet), totalFee);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, address(usdt), FeeType.USDT, hostItFee));
        marketplaceFacet.mintTicket(ticketId, FeeType.USDT, alice);
    }

    function test_directPayment_USDT_revertsInsufficientAllowance() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.USDT);
        ERC20Mock usdt = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDT));
        usdt.mint(alice, totalFee);
        vm.prank(alice);
        // Approve just under totalFee so allowance check fails on the second _payWithToken call (hostItFee)
        usdt.approve(address(marketplaceFacet), totalFee - 1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientAllowance.selector, address(usdt), FeeType.USDT, hostItFee));
        marketplaceFacet.mintTicket(ticketId, FeeType.USDT, alice);
    }

    // ======================================================================
    //               NON-REFUNDABLE: REFUND NOT ALLOWED
    // ======================================================================

    function test_directPayment_claimRefundRevertsForNonRefundable() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETH();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        vm.warp(fullTicketData.endTime);
        vm.prank(alice);
        vm.expectRevert(RefundNotEnabled.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, alice);
    }

    // ======================================================================
    //            NON-REFUNDABLE: WITHDRAW TICKET BALANCE REVERTS
    // ======================================================================

    function test_directPayment_withdrawTicketBalanceRevertsNoBalance() public {
        (uint64 ticketId,,,) = _mintTicketETH();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectRevert(InsufficientWithdrawBalance.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.ETH, withdrawer);
    }

    // ======================================================================
    //            NON-REFUNDABLE: WITHDRAW HOSTIT BALANCE
    // ======================================================================

    function test_directPayment_withdrawHostItBalanceETH() public {
        (,,, uint256 hostItFee) = _mintTicketETH();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.ETH, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.ETH, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), 0);
        assertEq(withdrawer.balance, hostItFee);
    }

    function test_directPayment_withdrawHostItBalanceUSDT() public {
        (,,, uint256 hostItFee, ERC20Mock usdt) = _mintTicketUSDT();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.USDT, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.USDT, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), 0);
        assertEq(usdt.balanceOf(withdrawer), hostItFee);
    }

    function test_directPayment_withdrawHostItBalanceUSDC() public {
        (,,, uint256 hostItFee, ERC20Mock usdc) = _mintTicketUSDC();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.USDC, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.USDC, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), 0);
        assertEq(usdc.balanceOf(withdrawer), hostItFee);
    }

    function test_directPayment_withdrawHostItBalanceRevertsIfZero() public {
        vm.expectRevert(InsufficientWithdrawBalance.selector);
        marketplaceFacet.withdrawHostItBalance(FeeType.ETH, withdrawer);
    }

    // ======================================================================
    //                    REFUNDABLE ESCROW: ETH
    // ======================================================================

    function test_refundable_ETH_fundsEscrowed() public {
        (uint64 ticketId,, uint256 fee, uint256 hostItFee) = _mintTicketETHRefundable();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
    }

    function test_refundable_ETH_organizerDoesNotReceiveFee() public {
        uint256 ownerBalanceBefore = owner.balance;
        _mintTicketETHRefundable();
        assertEq(owner.balance, ownerBalanceBefore);
    }

    function test_refundable_ETH_contractHoldsTotalFee() public {
        uint256 contractBalanceBefore = hostIt.balance;
        (,, uint256 fee, uint256 hostItFee) = _mintTicketETHRefundable();
        assertEq(hostIt.balance - contractBalanceBefore, fee + hostItFee);
    }

    function test_refundable_ETH_ticketMintedToBuyer() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);
        assertEq(ticket.ownerOf(tokenId), alice);
        assertEq(fullTicketData.soldTickets, 1);
    }

    function test_refundable_ETH_claimRefund() public {
        (uint64 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        vm.warp(fullTicketData.endTime);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketRefunded(ticketId, FeeType.ETH, fee, bob);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);

        assertEq(ticket.ownerOf(tokenId), owner);
        assertEq(bob.balance, fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
    }

    function test_refundable_ETH_claimRefundRevertsBeforeEndTime() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        vm.warp(fullTicketData.endTime - 1);
        vm.prank(alice);
        vm.expectRevert(RefundPeriodNotReached.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);
    }

    function test_refundable_ETH_claimRefundRevertsAfterRefundPeriod() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod() + 1);
        vm.prank(alice);
        vm.expectRevert(RefundPeriodExpired.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);
    }

    function test_refundable_ETH_claimRefundRevertsNonOwner() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(TicketNotOwned.selector, tokenId));
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);
    }

    function test_refundable_ETH_withdrawTicketBalanceAfterRefundPeriod() public {
        (uint64 ticketId,, uint256 fee,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.ETH, fee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.ETH, withdrawer);

        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        assertEq(withdrawer.balance, fee);
    }

    function test_refundable_ETH_withdrawTicketBalanceRevertsBeforeRefundPeriod() public {
        (uint64 ticketId,,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod() - 1);
        vm.expectRevert(WithdrawPeriodNotReached.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.ETH, withdrawer);
    }

    // ======================================================================
    //                    REFUNDABLE ESCROW: USDT
    // ======================================================================

    function test_refundable_USDT_fundsEscrowed() public {
        (uint64 ticketId,, uint256 fee, uint256 hostItFee,) = _mintTicketUSDTRefundable();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), hostItFee);
    }

    function test_refundable_USDT_organizerDoesNotReceiveFee() public {
        (,,,, ERC20Mock usdt) = _mintTicketUSDTRefundable();
        assertEq(usdt.balanceOf(owner), 0);
    }

    function test_refundable_USDT_contractHoldsTotalFee() public {
        (,, uint256 fee, uint256 hostItFee, ERC20Mock usdt) = _mintTicketUSDTRefundable();
        assertEq(usdt.balanceOf(hostIt), fee + hostItFee);
    }

    function test_refundable_USDT_claimRefund() public {
        (uint64 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee, ERC20Mock usdt) = _mintTicketUSDTRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        vm.warp(fullTicketData.endTime);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketRefunded(ticketId, FeeType.USDT, fee, bob);
        marketplaceFacet.claimRefund(ticketId, FeeType.USDT, tokenId, bob);

        assertEq(ticket.ownerOf(tokenId), owner);
        assertEq(usdt.balanceOf(bob), fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), hostItFee);
    }

    function test_refundable_USDT_withdrawTicketBalanceAfterRefundPeriod() public {
        (uint64 ticketId,, uint256 fee,, ERC20Mock usdt) = _mintTicketUSDTRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.USDT, fee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.USDT, withdrawer);

        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), 0);
        assertEq(usdt.balanceOf(withdrawer), fee);
    }

    // ======================================================================
    //                    REFUNDABLE ESCROW: USDC
    // ======================================================================

    function test_refundable_USDC_fundsEscrowed() public {
        (uint64 ticketId,, uint256 fee, uint256 hostItFee,) = _mintTicketUSDCRefundable();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), hostItFee);
    }

    function test_refundable_USDC_organizerDoesNotReceiveFee() public {
        (,,,, ERC20Mock usdc) = _mintTicketUSDCRefundable();
        assertEq(usdc.balanceOf(owner), 0);
    }

    function test_refundable_USDC_contractHoldsTotalFee() public {
        (,, uint256 fee, uint256 hostItFee, ERC20Mock usdc) = _mintTicketUSDCRefundable();
        assertEq(usdc.balanceOf(hostIt), fee + hostItFee);
    }

    function test_refundable_USDC_claimRefund() public {
        (uint64 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee, ERC20Mock usdc) = _mintTicketUSDCRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(fullTicketData.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        vm.warp(fullTicketData.endTime);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketRefunded(ticketId, FeeType.USDC, fee, bob);
        marketplaceFacet.claimRefund(ticketId, FeeType.USDC, tokenId, bob);

        assertEq(ticket.ownerOf(tokenId), owner);
        assertEq(usdc.balanceOf(bob), fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), hostItFee);
    }

    function test_refundable_USDC_withdrawTicketBalanceAfterRefundPeriod() public {
        (uint64 ticketId,, uint256 fee,, ERC20Mock usdc) = _mintTicketUSDCRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.USDC, fee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.USDC, withdrawer);

        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDC), 0);
        assertEq(usdc.balanceOf(withdrawer), fee);
    }

    // ======================================================================
    //            REFUNDABLE: HOSTIT BALANCE WITHDRAW AFTER ESCROW
    // ======================================================================

    function test_refundable_withdrawHostItBalanceETH() public {
        (,,, uint256 hostItFee) = _mintTicketETHRefundable();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.ETH, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.ETH, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), 0);
        assertEq(withdrawer.balance, hostItFee);
    }

    function test_refundable_withdrawHostItBalanceUSDT() public {
        (,,, uint256 hostItFee, ERC20Mock usdt) = _mintTicketUSDTRefundable();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.USDT, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.USDT, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), 0);
        assertEq(usdt.balanceOf(withdrawer), hostItFee);
    }

    function test_refundable_withdrawHostItBalanceUSDC() public {
        (,,, uint256 hostItFee, ERC20Mock usdc) = _mintTicketUSDCRefundable();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.USDC, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.USDC, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDC), 0);
        assertEq(usdc.balanceOf(withdrawer), hostItFee);
    }

    // ======================================================================
    //                          FEE CONFIGURATION
    // ======================================================================

    function test_setTicketFees() public {
        _createFreeTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        marketplaceFacet.setTicketFees(ticketId, _getFeeTypes(), _getFees());
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.ETH), _getFees()[0]);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.USDT), _getFees()[1]);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.USDC), _getFees()[2]);
    }

    function test_feeCalculation() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);
        assertEq(fee, ETH_FEE);
        assertEq(hostItFee, (ETH_FEE * 300) / 10_000);
        assertEq(totalFee, fee + hostItFee);
    }

    function test_feeNotEnabled_reverts() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        hoax(alice, 1 ether);
        vm.expectRevert(FeeNotEnabled.selector);
        marketplaceFacet.mintTicket{value: 1 ether}(ticketId, FeeType.WETH, alice);
    }

    // ======================================================================
    //            MIXED: REFUNDABLE + NON-REFUNDABLE HOSTIT ACCUMULATION
    // ======================================================================

    function test_hostItBalanceAccumulatesAcrossTickets() public {
        // Non-refundable ticket
        (,,, uint256 hostItFee1) = _mintTicketETH();
        // Refundable ticket
        (,,, uint256 hostItFee2) = _mintTicketETHRefundable();

        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee1 + hostItFee2);
    }

    // ======================================================================
    //                           FUZZ TESTS
    // ======================================================================

    function testFuzz_hostItFeeCalculation(uint256 fee) public view {
        fee = bound(fee, 0, type(uint256).max / 300);
        uint256 hostItFee = marketplaceFacet.getHostItFee(fee);
        assertEq(hostItFee, (fee * 300) / 10_000);
    }

    function testFuzz_totalFeeIsSumOfParts(uint256 fee) public {
        fee = bound(fee, 1, 1e30);

        _createFreeTicket();
        uint64 ticketId = factoryFacet.ticketCount();

        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.ETH;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        marketplaceFacet.setTicketFees(ticketId, feeTypes, fees);

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);
        assertEq(ticketFee, fee);
        assertEq(hostItFee, (fee * 300) / 10_000);
        assertEq(totalFee, ticketFee + hostItFee);
    }

    function testFuzz_directPayment_ETH_accounting(uint256 fee) public {
        fee = bound(fee, 1, 1e24);

        TicketData memory td = _getPaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.ETH;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        uint256 ownerBalBefore = owner.balance;
        uint256 contractBalBefore = hostIt.balance;

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);

        assertEq(owner.balance - ownerBalBefore, ticketFee);
        assertEq(hostIt.balance - contractBalBefore, hostItFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        assertEq(alice.balance, 0);
    }

    function testFuzz_directPayment_USDT_accounting(uint256 fee) public {
        fee = bound(fee, 1, 1e30);

        TicketData memory td = _getPaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.USDT;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.USDT);
        ERC20Mock usdt = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDT));
        usdt.mint(alice, totalFee);

        vm.prank(alice);
        usdt.approve(address(marketplaceFacet), totalFee);
        vm.prank(alice);
        marketplaceFacet.mintTicket(ticketId, FeeType.USDT, alice);

        assertEq(usdt.balanceOf(owner), ticketFee);
        assertEq(usdt.balanceOf(hostIt), hostItFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.USDT), hostItFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.USDT), 0);
        assertEq(usdt.balanceOf(alice), 0);
    }

    function testFuzz_refundable_ETH_escrow(uint256 fee) public {
        fee = bound(fee, 1, 1e24);

        TicketData memory td = _getRefundablePaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.ETH;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        uint256 ownerBalBefore = owner.balance;
        uint256 contractBalBefore = hostIt.balance;

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);

        assertEq(owner.balance, ownerBalBefore);
        assertEq(hostIt.balance - contractBalBefore, ticketFee + hostItFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), ticketFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
    }

    function testFuzz_refundable_ETH_claimWithinWindow(uint256 warpOffset) public {
        (uint64 ticketId, uint40 tokenId, uint256 fee, uint256 hostItFee) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        warpOffset = bound(warpOffset, 0, refundPeriod);
        vm.warp(ftd.endTime + warpOffset);

        vm.prank(alice);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);

        assertEq(bob.balance, fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
    }

    function testFuzz_refundable_ETH_claimRevertsBeforeEndTime(uint256 warpTo) public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        warpTo = bound(warpTo, block.timestamp, ftd.endTime - 1);
        vm.warp(warpTo);

        vm.prank(alice);
        vm.expectRevert(RefundPeriodNotReached.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);
    }

    function testFuzz_refundable_ETH_claimRevertsAfterWindow(uint256 extraTime) public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);

        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        extraTime = bound(extraTime, 1, 365 days);
        vm.warp(ftd.endTime + refundPeriod + extraTime);

        vm.prank(alice);
        vm.expectRevert(RefundPeriodExpired.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);
    }

    function testFuzz_refundable_ETH_withdrawAfterRefundPeriod(uint256 extraTime) public {
        (uint64 ticketId,, uint256 fee,) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        extraTime = bound(extraTime, 0, 365 days);
        vm.warp(ftd.endTime + refundPeriod + extraTime);

        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.ETH, withdrawer);
        assertEq(withdrawer.balance, fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
    }

    function testFuzz_refundable_ETH_withdrawRevertsBeforeRefundPeriod(uint256 warpTo) public {
        (uint64 ticketId,,,) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        warpTo = bound(warpTo, block.timestamp, ftd.endTime + refundPeriod - 1);
        vm.warp(warpTo);

        vm.expectRevert(WithdrawPeriodNotReached.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.ETH, withdrawer);
    }

    function testFuzz_directPayment_ETH_multipleBuyersAccumulate(uint8 buyerCount) public {
        buyerCount = uint8(bound(buyerCount, 1, 20));

        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        uint256 ownerBalBefore = owner.balance;

        for (uint8 i; i < buyerCount; ++i) {
            address buyer = makeAddr(string(abi.encodePacked("buyer", i)));
            hoax(buyer, totalFee);
            marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, buyer);
        }

        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee * buyerCount);
        assertEq(owner.balance - ownerBalBefore, ticketFee * buyerCount);

        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        assertEq(ftd.soldTickets, buyerCount);
    }

    function testFuzz_directPayment_ETH_revertsInsufficientValue(uint256 underpay) public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        underpay = bound(underpay, 1, totalFee);
        uint256 sent = totalFee - underpay;

        hoax(alice, totalFee);
        vm.expectRevert(abi.encodeWithSelector(TicketPurchaseFailed.selector, FeeType.ETH, totalFee));
        marketplaceFacet.mintTicket{value: sent}(ticketId, FeeType.ETH, alice);
    }

    function testFuzz_withdrawHostItBalance_ETH(uint256 fee) public {
        // fee must be >= 34 so hostItFee = fee * 300 / 10_000 > 0
        fee = bound(fee, 34, 1e24);

        TicketData memory td = _getPaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.ETH;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);

        marketplaceFacet.withdrawHostItBalance(FeeType.ETH, withdrawer);
        assertEq(withdrawer.balance, hostItFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), 0);
    }

    function testFuzz_refundable_ETH_fullLifecycle(uint256 fee, uint256 refundOffset) public {
        fee = bound(fee, 1, 1e24);
        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        refundOffset = bound(refundOffset, 0, refundPeriod);

        TicketData memory td = _getRefundablePaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.ETH;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        hoax(alice, totalFee);
        uint40 tokenId = marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, alice);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), ticketFee);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);
        vm.warp(ftd.endTime + refundOffset);

        vm.prank(alice);
        marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenId, bob);

        assertEq(bob.balance, ticketFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee);
        assertEq(ticket.ownerOf(tokenId), owner);
    }

    function testFuzz_refundable_ETH_multipleBuyersPartialRefund(uint8 buyerCount, uint8 refundCount) public {
        buyerCount = uint8(bound(buyerCount, 2, 10));
        refundCount = uint8(bound(refundCount, 1, buyerCount - 1));

        TicketData memory td = _getRefundablePaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.ETH;
        uint256[] memory fees = new uint256[](1);
        fees[0] = ETH_FEE;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.ETH);
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        address[] memory buyers = new address[](buyerCount);
        uint40[] memory tokenIds = new uint40[](buyerCount);
        for (uint8 i; i < buyerCount; ++i) {
            buyers[i] = makeAddr(string(abi.encodePacked("rbuyer", i)));
            hoax(buyers[i], totalFee);
            tokenIds[i] = marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.ETH, buyers[i]);
        }

        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), ticketFee * buyerCount);

        vm.warp(ftd.endTime);

        for (uint8 i; i < refundCount; ++i) {
            vm.prank(buyers[i]);
            ticket.approve(hostIt, tokenIds[i]);
            vm.prank(buyers[i]);
            marketplaceFacet.claimRefund(ticketId, FeeType.ETH, tokenIds[i], buyers[i]);
        }

        uint256 remaining = uint256(buyerCount - refundCount) * ticketFee;
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.ETH), remaining);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.ETH), hostItFee * buyerCount);
    }

    receive() external payable {}
}
