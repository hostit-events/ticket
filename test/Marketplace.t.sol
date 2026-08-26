// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {FullTicketData, TicketData} from "@ticket/libs/FactoryLib.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket/libs/MarketplaceLib.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket/libs/MarketplaceLib.sol";

contract MarketplaceTest is DeployedHostItTickets, ERC721Holder {
    uint256 internal constant BACKEND_PK = 0xB1AC;
    uint256 internal constant ATTACKER_PK = 0xBADBAD;
    address internal backend;

    function setUp() public override {
        super.setUp();
        backend = vm.addr(BACKEND_PK);
        vm.label(backend, "BACKEND");
        marketplaceFacet.setTrustedBackend(backend);
    }

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
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), 0);
    }

    // ======================================================================
    //                    NON-REFUNDABLE DIRECT PAYMENT: NATIVE
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
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
    }

    function test_directPayment_ETH_noTicketBalanceEscrowed() public {
        (uint64 ticketId,,,) = _mintTicketETH();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
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
        (,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);
        hoax(alice, totalFee);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId, FeeType.NATIVE, totalFee, 1);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);
    }

    function test_directPayment_ETH_multipleBuyersAccumulateHostItFees() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);

        hoax(bob, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, bob);

        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee * 2);
    }

    function test_directPayment_ETH_multipleBuyersPayOrganizer() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (uint256 fee,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        uint256 ownerBalanceBefore = owner.balance;

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);

        hoax(bob, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, bob);

        assertEq(owner.balance - ownerBalanceBefore, fee * 2);
    }

    function test_directPayment_ETH_revertsInsufficientValue() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);
        hoax(alice, totalFee);
        vm.expectRevert(abi.encodeWithSelector(InsufficientPayment.selector, FeeType.NATIVE, totalFee));
        marketplaceFacet.mintTicket{value: totalFee - 1}(ticketId, FeeType.NATIVE, alice);
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
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, alice);
    }

    // ======================================================================
    //            NON-REFUNDABLE: WITHDRAW TICKET BALANCE REVERTS
    // ======================================================================

    function test_directPayment_withdrawTicketBalanceRevertsNoBalance() public {
        (uint64 ticketId,,,) = _mintTicketETH();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);
        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectRevert(InsufficientWithdrawBalance.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.NATIVE, withdrawer);
    }

    // ======================================================================
    //            NON-REFUNDABLE: WITHDRAW HOSTIT BALANCE
    // ======================================================================

    function test_directPayment_withdrawHostItBalanceETH() public {
        (,,, uint256 hostItFee) = _mintTicketETH();
        vm.expectEmit(true, true, true, true, hostIt);
        emit HostItBalanceWithdrawn(FeeType.NATIVE, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.NATIVE, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), 0);
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
        marketplaceFacet.withdrawHostItBalance(FeeType.NATIVE, withdrawer);
    }

    // ======================================================================
    //                    REFUNDABLE ESCROW: NATIVE
    // ======================================================================

    function test_refundable_ETH_fundsEscrowed() public {
        (uint64 ticketId,, uint256 fee, uint256 hostItFee) = _mintTicketETHRefundable();
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), fee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
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
        emit TicketRefunded(ticketId, FeeType.NATIVE, fee, bob);
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);

        assertEq(ticket.ownerOf(tokenId), owner);
        assertEq(bob.balance, fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
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
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);
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
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);
    }

    function test_refundable_ETH_claimRefundRevertsNonOwner() public {
        (uint64 ticketId, uint40 tokenId,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(TicketNotOwned.selector, tokenId));
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);
    }

    function test_refundable_ETH_withdrawTicketBalanceAfterRefundPeriod() public {
        (uint64 ticketId,, uint256 fee,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod());
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketBalanceWithdrawn(ticketId, FeeType.NATIVE, fee, withdrawer);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.NATIVE, withdrawer);

        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
        assertEq(withdrawer.balance, fee);
    }

    function test_refundable_ETH_withdrawTicketBalanceRevertsBeforeRefundPeriod() public {
        (uint64 ticketId,,,) = _mintTicketETHRefundable();
        FullTicketData memory fullTicketData = factoryFacet.ticketData(ticketId);

        vm.warp(fullTicketData.endTime + marketplaceFacet.getRefundPeriod() - 1);
        vm.expectRevert(WithdrawPeriodNotReached.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.NATIVE, withdrawer);
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
        emit HostItBalanceWithdrawn(FeeType.NATIVE, hostItFee, withdrawer);
        marketplaceFacet.withdrawHostItBalance(FeeType.NATIVE, withdrawer);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), 0);
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

    function test_updateTicketFees() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        FeeType[] memory feeTypes = _getFeeTypes();
        uint256[] memory fees = new uint256[](3);
        fees[0] = ETH_FEE * 2;
        fees[1] = USDT_FEE * 2;
        fees[2] = USDC_FEE * 2;
        marketplaceFacet.updateTicketFees(ticketId, feeTypes, fees);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.NATIVE), fees[0]);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.USDT), fees[1]);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.USDC), fees[2]);
    }

    function test_feeCalculation() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);
        assertEq(fee, ETH_FEE);
        assertEq(hostItFee, (ETH_FEE * 300) / 10_000);
        assertEq(totalFee, fee + hostItFee);
    }

    function test_feeNotEnabled_reverts() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        hoax(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(FeeNotEnabled.selector, ticketId, FeeType.WNATIVE));
        marketplaceFacet.mintTicket{value: 1 ether}(ticketId, FeeType.WNATIVE, alice);
    }

    // ======================================================================
    //                    TICKET SOLD OUT
    // ======================================================================

    function test_mintTicket_revertsTicketSoldOut() public {
        TicketData memory td = _getFreeTicketData();
        td.maxTickets = 1;
        factoryFacet.createTicket(td, _getZeroFeeType(), _getZeroFee());
        uint64 ticketId = factoryFacet.ticketCount();
        marketplaceFacet.mintTicket(ticketId, FeeType.NONE, alice);
        vm.expectRevert(TicketSoldOut.selector);
        marketplaceFacet.mintTicket(ticketId, FeeType.NONE, bob);
    }

    // ======================================================================
    //                    MAX TICKETS PER USER
    // ======================================================================

    function test_mintTicket_revertsMaxTicketsHeld() public {
        TicketData memory td = _getFreeTicketData();
        td.maxTicketsPerUser = 1;
        factoryFacet.createTicket(td, _getZeroFeeType(), _getZeroFee());
        uint64 ticketId = factoryFacet.ticketCount();
        // First mint: balance 0 >= 1 is false → succeeds; balance becomes 1.
        marketplaceFacet.mintTicket(ticketId, FeeType.NONE, alice);
        // Second mint: balance 1 >= 1 is true → reverts.
        vm.expectRevert(MaxTicketsHeld.selector);
        marketplaceFacet.mintTicket(ticketId, FeeType.NONE, alice);
    }

    // ======================================================================
    //                    PURCHASE TIME CHECKS
    // ======================================================================

    function test_mintTicket_revertsPurchaseTimeNotReached() public {
        TicketData memory td = _getFreeTicketData();
        td.purchaseStartTime = uint48(block.timestamp + 1 days);
        td.startTime = uint48(block.timestamp + 2 days);
        td.endTime = uint48(block.timestamp + 3 days);
        factoryFacet.createTicket(td, _getZeroFeeType(), _getZeroFee());
        uint64 ticketId = factoryFacet.ticketCount();
        vm.expectRevert(PurchaseTimeNotReached.selector);
        marketplaceFacet.mintTicket(ticketId, FeeType.NONE, alice);
    }

    function test_mintTicket_revertsAfterEventEnded() public {
        _createFreeTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        vm.warp(ftd.endTime + 1);
        vm.expectRevert(PurchaseTimeNotReached.selector);
        marketplaceFacet.mintTicket(ticketId, FeeType.NONE, alice);
    }

    // ======================================================================
    //            SET TICKET FEES: REVERT CASES
    // ======================================================================

    function test_updateTicketFees_revertsZeroFee() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = 0;
        vm.expectRevert(abi.encodeWithSelector(ZeroFee.selector, FeeType.NATIVE));
        marketplaceFacet.updateTicketFees(ticketId, feeTypes, fees);
    }

    function test_updateTicketFees_updatesExistingFee() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = ETH_FEE * 2;
        marketplaceFacet.updateTicketFees(ticketId, feeTypes, fees);
        assertEq(marketplaceFacet.getTicketFee(ticketId, FeeType.NATIVE), ETH_FEE * 2);
    }

    function test_updateTicketFees_revertsInvalidFeeConfig() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        FeeType[] memory feeTypes = new FeeType[](2);
        feeTypes[0] = FeeType.NATIVE;
        feeTypes[1] = FeeType.USDT;
        uint256[] memory fees = new uint256[](1);
        fees[0] = ETH_FEE;
        vm.expectRevert(InvalidFeeConfig.selector);
        marketplaceFacet.updateTicketFees(ticketId, feeTypes, fees);
    }

    function test_updateTicketFees_revertsNonAdmin() public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        vm.prank(alice);
        vm.expectRevert();
        marketplaceFacet.updateTicketFees(ticketId, _getFeeTypes(), _getFees());
    }

    function test_updateTicketFees_revertsTicketIsFree() public {
        _createFreeTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        vm.expectRevert(TicketIsFree.selector);
        marketplaceFacet.updateTicketFees(ticketId, _getFeeTypes(), _getFees());
    }

    // ======================================================================
    //            WITHDRAW TO CONTRACT REVERTS
    // ======================================================================

    function test_withdrawHostItBalance_revertsNonOwner() public {
        _mintTicketETH();
        vm.prank(alice);
        vm.expectRevert();
        marketplaceFacet.withdrawHostItBalance(FeeType.NATIVE, withdrawer);
    }

    // ======================================================================
    //            TICKET DOES NOT EXIST
    // ======================================================================

    function test_mintTicket_revertsTicketDoesNotExist() public {
        vm.expectRevert();
        marketplaceFacet.mintTicket(999, FeeType.NONE, alice);
    }

    // ======================================================================
    //            MIXED: REFUNDABLE + NON-REFUNDABLE HOSTIT ACCUMULATION
    // ======================================================================

    function test_hostItBalanceAccumulatesAcrossTickets() public {
        // Non-refundable ticket
        (,,, uint256 hostItFee1) = _mintTicketETH();
        // Refundable ticket
        (,,, uint256 hostItFee2) = _mintTicketETHRefundable();

        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee1 + hostItFee2);
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

        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();

        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        marketplaceFacet.updateTicketFees(ticketId, feeTypes, fees);

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);
        assertEq(ticketFee, fee);
        assertEq(hostItFee, (fee * 300) / 10_000);
        assertEq(totalFee, ticketFee + hostItFee);
    }

    function testFuzz_directPayment_ETH_accounting(uint256 fee) public {
        fee = bound(fee, 1, 1e24);

        TicketData memory td = _getPaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        uint256 ownerBalBefore = owner.balance;
        uint256 contractBalBefore = hostIt.balance;

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);

        assertEq(owner.balance - ownerBalBefore, ticketFee);
        assertEq(hostIt.balance - contractBalBefore, hostItFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
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
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        uint256 ownerBalBefore = owner.balance;
        uint256 contractBalBefore = hostIt.balance;

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);

        assertEq(owner.balance, ownerBalBefore);
        assertEq(hostIt.balance - contractBalBefore, ticketFee + hostItFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), ticketFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
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
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);

        assertEq(bob.balance, fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
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
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);
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
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);
    }

    function testFuzz_refundable_ETH_withdrawAfterRefundPeriod(uint256 extraTime) public {
        (uint64 ticketId,, uint256 fee,) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        extraTime = bound(extraTime, 0, 365 days);
        vm.warp(ftd.endTime + refundPeriod + extraTime);

        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.NATIVE, withdrawer);
        assertEq(withdrawer.balance, fee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
    }

    function testFuzz_refundable_ETH_withdrawRevertsBeforeRefundPeriod(uint256 warpTo) public {
        (uint64 ticketId,,,) = _mintTicketETHRefundable();
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);

        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        warpTo = bound(warpTo, block.timestamp, ftd.endTime + refundPeriod - 1);
        vm.warp(warpTo);

        vm.expectRevert(WithdrawPeriodNotReached.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.NATIVE, withdrawer);
    }

    function testFuzz_directPayment_ETH_multipleBuyersAccumulate(uint8 buyerCount) public {
        buyerCount = uint8(bound(buyerCount, 1, 20));

        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        uint256 ownerBalBefore = owner.balance;

        for (uint8 i; i < buyerCount; ++i) {
            address buyer = makeAddr(string(abi.encodePacked("buyer", i)));
            hoax(buyer, totalFee);
            marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, buyer);
        }

        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee * buyerCount);
        assertEq(owner.balance - ownerBalBefore, ticketFee * buyerCount);

        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        assertEq(ftd.soldTickets, buyerCount);
    }

    function testFuzz_directPayment_ETH_revertsInsufficientValue(uint256 underpay) public {
        _createPaidTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        (,, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        underpay = bound(underpay, 1, totalFee);
        uint256 sent = totalFee - underpay;

        hoax(alice, totalFee);
        vm.expectRevert(abi.encodeWithSelector(InsufficientPayment.selector, FeeType.NATIVE, totalFee));
        marketplaceFacet.mintTicket{value: sent}(ticketId, FeeType.NATIVE, alice);
    }

    function testFuzz_withdrawHostItBalance_ETH(uint256 fee) public {
        // fee must be >= 34 so hostItFee = fee * 300 / 10_000 > 0
        fee = bound(fee, 34, 1e24);

        TicketData memory td = _getPaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);

        hoax(alice, totalFee);
        marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);

        marketplaceFacet.withdrawHostItBalance(FeeType.NATIVE, withdrawer);
        assertEq(withdrawer.balance, hostItFee);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), 0);
    }

    function testFuzz_refundable_ETH_fullLifecycle(uint256 fee, uint256 refundOffset) public {
        fee = bound(fee, 1, 1e24);
        uint256 refundPeriod = marketplaceFacet.getRefundPeriod();
        refundOffset = bound(refundOffset, 0, refundPeriod);

        TicketData memory td = _getRefundablePaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        hoax(alice, totalFee);
        uint40 tokenId = marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, alice);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), ticketFee);

        vm.prank(alice);
        ticket.approve(hostIt, tokenId);
        vm.warp(ftd.endTime + refundOffset);

        vm.prank(alice);
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, bob);

        assertEq(bob.balance, ticketFee);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), 0);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee);
        assertEq(ticket.ownerOf(tokenId), owner);
    }

    function testFuzz_refundable_ETH_multipleBuyersPartialRefund(uint8 buyerCount, uint8 refundCount) public {
        buyerCount = uint8(bound(buyerCount, 2, 10));
        refundCount = uint8(bound(refundCount, 1, buyerCount - 1));

        TicketData memory td = _getRefundablePaidTicketData();
        FeeType[] memory feeTypes = new FeeType[](1);
        feeTypes[0] = FeeType.NATIVE;
        uint256[] memory fees = new uint256[](1);
        fees[0] = ETH_FEE;
        factoryFacet.createTicket(td, feeTypes, fees);
        uint64 ticketId = factoryFacet.ticketCount();

        (uint256 ticketFee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId, FeeType.NATIVE);
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        ITicket ticket = ITicket(ftd.ticketAddress);

        address[] memory buyers = new address[](buyerCount);
        uint40[] memory tokenIds = new uint40[](buyerCount);
        for (uint8 i; i < buyerCount; ++i) {
            buyers[i] = makeAddr(string(abi.encodePacked("rbuyer", i)));
            hoax(buyers[i], totalFee);
            tokenIds[i] = marketplaceFacet.mintTicket{value: totalFee}(ticketId, FeeType.NATIVE, buyers[i]);
        }

        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), ticketFee * buyerCount);

        vm.warp(ftd.endTime);

        for (uint8 i; i < refundCount; ++i) {
            vm.prank(buyers[i]);
            ticket.approve(hostIt, tokenIds[i]);
            vm.prank(buyers[i]);
            marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenIds[i], buyers[i]);
        }

        uint256 remaining = uint256(buyerCount - refundCount) * ticketFee;
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.NATIVE), remaining);
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), hostItFee * buyerCount);
    }

    receive() external payable {}

    // ======================================================================
    //                    FIAT PAYMENT — HELPERS
    // ======================================================================

    function _voucher(uint64 ticketId, address buyer, uint256 amount, bytes32 paymentId, uint48 expiresAt)
        internal
        pure
        returns (FiatVoucher memory)
    {
        return
            FiatVoucher({ticketId: ticketId, buyer: buyer, amount: amount, paymentId: paymentId, expiresAt: expiresAt});
    }

    function _signVoucher(FiatVoucher memory v, uint256 pk) internal view returns (bytes memory) {
        bytes32 domain = marketplaceFacet.getFiatDomainSeparator();
        bytes32 structHash = marketplaceFacet.hashFiatVoucher(v);
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
        (uint8 vv, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, vv);
    }

    function _sign(FiatVoucher memory v) internal view returns (bytes memory) {
        return _signVoucher(v, BACKEND_PK);
    }

    function _createFiatTicket() internal returns (uint64) {
        // Reuse the standard paid ticket data; crypto fees still configured but unused by fiat path.
        _createPaidTicket();
        return factoryFacet.ticketCount();
    }

    function _createRefundableFiatTicket() internal returns (uint64) {
        TicketData memory td = _getRefundablePaidTicketData();
        factoryFacet.createTicket(td, _getFeeTypes(), _getFees());
        return factoryFacet.ticketCount();
    }

    // ======================================================================
    //                    FIAT: DIRECT PATH — SINGLE
    // ======================================================================

    function test_fiat_direct_success() public {
        uint64 ticketId = _createFiatTicket();
        bytes32 pid = keccak256("p-1");
        uint256 amount = 1500;

        vm.prank(backend);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId, FeeType.FIAT, amount, 1);
        vm.expectEmit(true, true, true, true, hostIt);
        emit FiatTicketMinted(ticketId, alice, 1, amount, pid);
        uint40 tokenId = marketplaceFacet.mintFiatTicket(ticketId, alice, amount, pid);

        assertEq(tokenId, 1);
        assertTrue(marketplaceFacet.isFiatPaidToken(ticketId, tokenId));
        assertTrue(marketplaceFacet.isFiatPaymentIdUsed(pid));
        assertEq(marketplaceFacet.getTicketFiatRevenue(ticketId), amount);

        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        assertEq(ITicket(ftd.ticketAddress).ownerOf(tokenId), alice);
        assertEq(ftd.soldTickets, 1);
    }

    function test_fiat_direct_revertsNonBackend() public {
        uint64 ticketId = _createFiatTicket();
        vm.prank(alice);
        vm.expectRevert(UnauthorizedBackend.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p"));
    }

    function test_fiat_direct_replayRevertsSamePath() public {
        uint64 ticketId = _createFiatTicket();
        bytes32 pid = keccak256("dup");
        vm.prank(backend);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, pid);

        vm.prank(backend);
        vm.expectRevert(abi.encodeWithSelector(PaymentIdAlreadyUsed.selector, pid));
        marketplaceFacet.mintFiatTicket(ticketId, bob, 100, pid);
    }

    function test_fiat_direct_revertsZeroPaymentId() public {
        uint64 ticketId = _createFiatTicket();
        vm.prank(backend);
        vm.expectRevert(InvalidPaymentId.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, bytes32(0));
    }

    function test_fiat_direct_revertsZeroAmount() public {
        uint64 ticketId = _createFiatTicket();
        vm.prank(backend);
        vm.expectRevert(ZeroFiatAmount.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 0, keccak256("p"));
    }

    function test_fiat_direct_revertsFreeTicket() public {
        _createFreeTicket();
        uint64 ticketId = factoryFacet.ticketCount();
        vm.prank(backend);
        vm.expectRevert(TicketIsFree.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p"));
    }

    // ======================================================================
    //                    FIAT: DIRECT PATH — PRE-MINT INVARIANTS
    // ======================================================================

    function test_fiat_direct_revertsSoldOut() public {
        TicketData memory td = _getPaidTicketData();
        td.maxTickets = 1;
        factoryFacet.createTicket(td, _getFeeTypes(), _getFees());
        uint64 ticketId = factoryFacet.ticketCount();

        vm.prank(backend);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p1"));

        vm.prank(backend);
        vm.expectRevert(TicketSoldOut.selector);
        marketplaceFacet.mintFiatTicket(ticketId, bob, 100, keccak256("p2"));
    }

    function test_fiat_direct_revertsPurchaseTimeNotReached() public {
        TicketData memory td = _getPaidTicketData();
        td.purchaseStartTime = uint48(block.timestamp + 1 days);
        td.startTime = uint48(block.timestamp + 2 days);
        td.endTime = uint48(block.timestamp + 3 days);
        factoryFacet.createTicket(td, _getFeeTypes(), _getFees());
        uint64 ticketId = factoryFacet.ticketCount();

        vm.prank(backend);
        vm.expectRevert(PurchaseTimeNotReached.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p"));
    }

    function test_fiat_direct_revertsMaxTicketsHeld() public {
        uint64 ticketId = _createFiatTicket();
        vm.prank(backend);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p1"));

        vm.prank(backend);
        vm.expectRevert(MaxTicketsHeld.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p2"));
    }

    // ======================================================================
    //                    FIAT: VOUCHER PATH — SINGLE
    // ======================================================================

    function test_fiat_voucher_success() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher memory v = _voucher(ticketId, alice, 250, keccak256("v-1"), uint48(block.timestamp + 1 hours));
        bytes memory sig = _sign(v);

        vm.prank(charlie); // anyone can submit
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId, FeeType.FIAT, 250, 1);
        vm.expectEmit(true, true, true, true, hostIt);
        emit FiatTicketMinted(ticketId, alice, 1, 250, v.paymentId);
        uint40 tokenId = marketplaceFacet.redeemFiatVoucher(v, sig);

        assertEq(tokenId, 1);
        assertTrue(marketplaceFacet.isFiatPaidToken(ticketId, tokenId));
        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        assertEq(ITicket(ftd.ticketAddress).ownerOf(tokenId), alice);
    }

    function test_fiat_voucher_revertsExpired() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher memory v = _voucher(ticketId, alice, 100, keccak256("v"), uint48(block.timestamp + 1));
        bytes memory sig = _sign(v);

        vm.warp(v.expiresAt + 1);
        vm.expectRevert(VoucherExpired.selector);
        marketplaceFacet.redeemFiatVoucher(v, sig);
    }

    function test_fiat_voucher_revertsBadSigner() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher memory v = _voucher(ticketId, alice, 100, keccak256("v"), uint48(block.timestamp + 1 hours));
        bytes memory sig = _signVoucher(v, ATTACKER_PK);

        vm.expectRevert(InvalidVoucherSignature.selector);
        marketplaceFacet.redeemFiatVoucher(v, sig);
    }

    function test_fiat_voucher_revertsTamperedVoucher() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher memory v = _voucher(ticketId, alice, 100, keccak256("v"), uint48(block.timestamp + 1 hours));
        bytes memory sig = _sign(v);

        // Tamper: change buyer after signing
        v.buyer = bob;
        vm.expectRevert(InvalidVoucherSignature.selector);
        marketplaceFacet.redeemFiatVoucher(v, sig);
    }

    function test_fiat_voucher_replayReverts() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher memory v = _voucher(ticketId, alice, 100, keccak256("v"), uint48(block.timestamp + 1 hours));
        bytes memory sig = _sign(v);
        marketplaceFacet.redeemFiatVoucher(v, sig);

        vm.expectRevert(abi.encodeWithSelector(PaymentIdAlreadyUsed.selector, v.paymentId));
        marketplaceFacet.redeemFiatVoucher(v, sig);
    }

    function test_fiat_crossPathReplayReverts() public {
        uint64 ticketId = _createFiatTicket();
        bytes32 pid = keccak256("cross");

        FiatVoucher memory v = _voucher(ticketId, alice, 100, pid, uint48(block.timestamp + 1 hours));
        bytes memory sig = _sign(v);
        marketplaceFacet.redeemFiatVoucher(v, sig);

        vm.prank(backend);
        vm.expectRevert(abi.encodeWithSelector(PaymentIdAlreadyUsed.selector, pid));
        marketplaceFacet.mintFiatTicket(ticketId, bob, 100, pid);
    }

    // ======================================================================
    //                    FIAT: BATCH — DIRECT
    // ======================================================================

    function test_fiat_batchDirect_success() public {
        uint64 ticketId = _createFiatTicket();

        uint64[] memory tids = new uint64[](2);
        tids[0] = ticketId;
        tids[1] = ticketId;
        address[] memory buyers = new address[](2);
        buyers[0] = alice;
        buyers[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        bytes32[] memory pids = new bytes32[](2);
        pids[0] = keccak256("b-1");
        pids[1] = keccak256("b-2");

        vm.prank(backend);
        uint40[] memory tokenIds = marketplaceFacet.batchMintFiatTickets(tids, buyers, amounts, pids);

        assertEq(tokenIds.length, 2);
        assertEq(tokenIds[0], 1);
        assertEq(tokenIds[1], 2);
        assertEq(marketplaceFacet.getTicketFiatRevenue(ticketId), 300);
        assertTrue(marketplaceFacet.isFiatPaidToken(ticketId, 1));
        assertTrue(marketplaceFacet.isFiatPaidToken(ticketId, 2));
    }

    function test_fiat_batchDirect_atomicRollback() public {
        uint64 ticketId = _createFiatTicket();
        bytes32 dup = keccak256("dup");

        // Pre-consume the dup payment id via single mint.
        vm.prank(backend);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, dup);

        uint64[] memory tids = new uint64[](2);
        tids[0] = ticketId;
        tids[1] = ticketId;
        address[] memory buyers = new address[](2);
        buyers[0] = bob;
        buyers[1] = charlie;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        bytes32[] memory pids = new bytes32[](2);
        bytes32 freshPid = keccak256("fresh");
        pids[0] = freshPid;
        pids[1] = dup; // collision on item 2

        vm.prank(backend);
        vm.expectRevert(abi.encodeWithSelector(PaymentIdAlreadyUsed.selector, dup));
        marketplaceFacet.batchMintFiatTickets(tids, buyers, amounts, pids);

        // Item 1 must NOT have been persisted (atomic rollback).
        assertFalse(marketplaceFacet.isFiatPaymentIdUsed(freshPid));
    }

    function test_fiat_batchDirect_revertsLengthMismatch() public {
        uint64[] memory tids = new uint64[](1);
        address[] memory buyers = new address[](2);
        uint256[] memory amounts = new uint256[](1);
        bytes32[] memory pids = new bytes32[](1);

        vm.prank(backend);
        vm.expectRevert(BatchLengthMismatch.selector);
        marketplaceFacet.batchMintFiatTickets(tids, buyers, amounts, pids);
    }

    function test_fiat_batchDirect_revertsEmpty() public {
        uint64[] memory tids = new uint64[](0);
        address[] memory buyers = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes32[] memory pids = new bytes32[](0);

        vm.prank(backend);
        vm.expectRevert(BatchLengthMismatch.selector);
        marketplaceFacet.batchMintFiatTickets(tids, buyers, amounts, pids);
    }

    function test_fiat_batchDirect_revertsNonBackend() public {
        uint64 ticketId = _createFiatTicket();
        uint64[] memory tids = new uint64[](1);
        tids[0] = ticketId;
        address[] memory buyers = new address[](1);
        buyers[0] = alice;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        bytes32[] memory pids = new bytes32[](1);
        pids[0] = keccak256("p");

        vm.prank(alice);
        vm.expectRevert(UnauthorizedBackend.selector);
        marketplaceFacet.batchMintFiatTickets(tids, buyers, amounts, pids);
    }

    // ======================================================================
    //                    FIAT: BATCH — VOUCHER
    // ======================================================================

    function test_fiat_batchVoucher_success() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher[] memory vs = new FiatVoucher[](2);
        vs[0] = _voucher(ticketId, alice, 100, keccak256("bv-1"), uint48(block.timestamp + 1 hours));
        vs[1] = _voucher(ticketId, bob, 200, keccak256("bv-2"), uint48(block.timestamp + 1 hours));
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(vs[0]);
        sigs[1] = _sign(vs[1]);

        uint40[] memory tokenIds = marketplaceFacet.batchRedeemFiatVouchers(vs, sigs);
        assertEq(tokenIds[0], 1);
        assertEq(tokenIds[1], 2);
        assertEq(marketplaceFacet.getTicketFiatRevenue(ticketId), 300);
    }

    function test_fiat_batchVoucher_oneBadSigRollsBack() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher[] memory vs = new FiatVoucher[](2);
        vs[0] = _voucher(ticketId, alice, 100, keccak256("bvr-1"), uint48(block.timestamp + 1 hours));
        vs[1] = _voucher(ticketId, bob, 200, keccak256("bvr-2"), uint48(block.timestamp + 1 hours));
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(vs[0]);
        sigs[1] = _signVoucher(vs[1], ATTACKER_PK); // bad sig on item 2

        vm.expectRevert(InvalidVoucherSignature.selector);
        marketplaceFacet.batchRedeemFiatVouchers(vs, sigs);

        assertFalse(marketplaceFacet.isFiatPaymentIdUsed(vs[0].paymentId));
    }

    function test_fiat_batchVoucher_revertsLengthMismatch() public {
        FiatVoucher[] memory vs = new FiatVoucher[](1);
        bytes[] memory sigs = new bytes[](2);
        vm.expectRevert(BatchLengthMismatch.selector);
        marketplaceFacet.batchRedeemFiatVouchers(vs, sigs);
    }

    function test_fiat_batchVoucher_revertsEmpty() public {
        FiatVoucher[] memory vs = new FiatVoucher[](0);
        bytes[] memory sigs = new bytes[](0);
        vm.expectRevert(BatchLengthMismatch.selector);
        marketplaceFacet.batchRedeemFiatVouchers(vs, sigs);
    }

    // ======================================================================
    //                    FIAT: KILL SWITCH (trustedBackend == 0)
    // ======================================================================

    function test_fiat_killSwitch_disablesDirect() public {
        marketplaceFacet.setTrustedBackend(address(0));
        uint64 ticketId = _createFiatTicket();
        vm.prank(backend);
        vm.expectRevert(UnauthorizedBackend.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p"));
    }

    function test_fiat_killSwitch_disablesVoucher() public {
        uint64 ticketId = _createFiatTicket();
        FiatVoucher memory v = _voucher(ticketId, alice, 100, keccak256("p"), uint48(block.timestamp + 1 hours));
        bytes memory sig = _sign(v);

        marketplaceFacet.setTrustedBackend(address(0));

        vm.expectRevert(InvalidVoucherSignature.selector);
        marketplaceFacet.redeemFiatVoucher(v, sig);
    }

    // ======================================================================
    //                    FIAT: LEDGER — NO HOSTIT FEE
    // ======================================================================

    function test_fiat_noHostItFeeAccumulated() public {
        uint64 ticketId = _createFiatTicket();
        vm.prank(backend);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 10_000, keccak256("p"));

        assertEq(marketplaceFacet.getHostItBalance(FeeType.FIAT), 0);
        assertEq(marketplaceFacet.getTicketBalance(ticketId, FeeType.FIAT), 0);
        // Crypto ledger untouched
        assertEq(marketplaceFacet.getHostItBalance(FeeType.NATIVE), 0);
    }

    // ======================================================================
    //                    GUARDS ON EXISTING CRYPTO PATHS
    // ======================================================================

    function test_guards_mintTicket_revertsForFIAT() public {
        uint64 ticketId = _createFiatTicket();
        vm.expectRevert(FiatFeeTypeNotMintable.selector);
        marketplaceFacet.mintTicket(ticketId, FeeType.FIAT, alice);
    }

    function test_guards_updateTicketFees_revertsForFIAT() public {
        uint64 ticketId = _createFiatTicket();
        FeeType[] memory fts = new FeeType[](1);
        fts[0] = FeeType.FIAT;
        uint256[] memory fs = new uint256[](1);
        fs[0] = 1000;
        vm.expectRevert(FiatFeeNotSettable.selector);
        marketplaceFacet.updateTicketFees(ticketId, fts, fs);
    }

    function test_guards_updateTicketFees_revertsForFIATInMixedList() public {
        uint64 ticketId = _createFiatTicket();
        FeeType[] memory fts = new FeeType[](2);
        fts[0] = FeeType.NATIVE;
        fts[1] = FeeType.FIAT;
        uint256[] memory fs = new uint256[](2);
        fs[0] = 1e18;
        fs[1] = 1000;
        vm.expectRevert(FiatFeeNotSettable.selector);
        marketplaceFacet.updateTicketFees(ticketId, fts, fs);
    }

    function test_guards_createTicket_revertsForFIATFee() public {
        // createTicket → setTicketFees → FiatFeeNotSettable guard fires.
        TicketData memory td = _getPaidTicketData();
        FeeType[] memory fts = new FeeType[](1);
        fts[0] = FeeType.FIAT;
        uint256[] memory fs = new uint256[](1);
        fs[0] = 1000;
        vm.expectRevert(FiatFeeNotSettable.selector);
        factoryFacet.createTicket(td, fts, fs);
    }

    function test_guards_claimRefund_revertsForFiatPaidToken() public {
        uint64 ticketId = _createRefundableFiatTicket();
        vm.prank(backend);
        uint40 tokenId = marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p"));

        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        vm.warp(ftd.endTime);
        vm.prank(alice);
        vm.expectRevert(FiatTicketNotRefundable.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.FIAT, tokenId, alice);
    }

    function test_guards_claimRefund_revertsForFiatTokenEvenWhenFeeTypeNATIVE() public {
        // A fiat-paid token should be unrefundable regardless of which FeeType the caller passes.
        uint64 ticketId = _createRefundableFiatTicket();
        vm.prank(backend);
        uint40 tokenId = marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("p"));

        FullTicketData memory ftd = factoryFacet.ticketData(ticketId);
        vm.warp(ftd.endTime);
        vm.prank(alice);
        vm.expectRevert(FiatTicketNotRefundable.selector);
        marketplaceFacet.claimRefund(ticketId, FeeType.NATIVE, tokenId, alice);
    }

    function test_guards_withdrawTicketBalance_revertsForFIAT() public {
        uint64 ticketId = _createFiatTicket();
        vm.expectRevert(FiatBalanceNotWithdrawable.selector);
        marketplaceFacet.withdrawTicketBalance(ticketId, FeeType.FIAT, withdrawer);
    }

    function test_guards_withdrawHostItBalance_revertsForFIAT() public {
        vm.expectRevert(FiatBalanceNotWithdrawable.selector);
        marketplaceFacet.withdrawHostItBalance(FeeType.FIAT, withdrawer);
    }

    // ======================================================================
    //                    OWNER ROTATION
    // ======================================================================

    function test_setTrustedBackend_revertsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        marketplaceFacet.setTrustedBackend(alice);
    }

    function test_setTrustedBackend_rotates() public {
        address newBackend = makeAddr("newBackend");
        vm.expectEmit(true, true, true, true, hostIt);
        emit TrustedBackendUpdated(backend, newBackend);
        marketplaceFacet.setTrustedBackend(newBackend);
        assertEq(marketplaceFacet.getTrustedBackend(), newBackend);

        // Old backend can no longer call.
        uint64 ticketId = _createFiatTicket();
        vm.prank(backend);
        vm.expectRevert(UnauthorizedBackend.selector);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("rot"));

        // New backend can.
        vm.prank(newBackend);
        marketplaceFacet.mintFiatTicket(ticketId, alice, 100, keccak256("rot"));
    }

    // ======================================================================
    //                    EIP-712 SANITY
    // ======================================================================

    function test_eip712_domainSeparator() public view {
        bytes32 expected = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("HostItTickets")),
                keccak256(bytes("1")),
                block.chainid,
                hostIt
            )
        );
        assertEq(marketplaceFacet.getFiatDomainSeparator(), expected);
    }

    function test_eip712_voucherTypehash() public view {
        bytes32 expected =
            keccak256("FiatVoucher(uint64 ticketId,address buyer,uint256 amount,bytes32 paymentId,uint48 expiresAt)");
        assertEq(marketplaceFacet.getFiatVoucherTypehash(), expected);
    }

    function test_eip712_structHashMatchesAbiEncode() public view {
        FiatVoucher memory v = _voucher(7, alice, 1234, keccak256("typehash-check"), uint48(block.timestamp + 1 hours));
        bytes32 expected = keccak256(
            abi.encode(
                marketplaceFacet.getFiatVoucherTypehash(), v.ticketId, v.buyer, v.amount, v.paymentId, v.expiresAt
            )
        );
        assertEq(marketplaceFacet.hashFiatVoucher(v), expected);
    }
}
