// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Selectors} from "@diamond-test/helpers/Selectors.sol";
import {Utils} from "@diamond-test/helpers/Utils.sol";
import {IFacet} from "@diamond/interfaces/IFacet.sol";
import {CheckInFacet} from "@ticket/facets/CheckInFacet.sol";
import {FactoryFacet} from "@ticket/facets/FactoryFacet.sol";
import {MarketplaceFacet} from "@ticket/facets/MarketplaceFacet.sol";
import {Test} from "forge-std/Test.sol";

contract ExportSelectorsTest is Test {
    CheckInFacet internal checkIn;
    FactoryFacet internal factory;
    MarketplaceFacet internal marketplace;

    function setUp() public {
        checkIn = new CheckInFacet();
        factory = new FactoryFacet();
        marketplace = new MarketplaceFacet();
    }

    function testExport_CheckIn() public view {
        bytes4[] memory expected = new bytes4[](6);
        expected[0] = checkIn.checkIn.selector;
        expected[1] = checkIn.checkInBatch.selector;
        expected[2] = checkIn.getCheckedIn.selector;
        expected[3] = checkIn.getCheckedInForDay.selector;
        expected[4] = checkIn.isCheckedIn.selector;
        expected[5] = checkIn.isCheckedInForDay.selector;
        _assertExports(IFacet(address(checkIn)), expected);
    }

    function testExport_Factory() public view {
        bytes4[] memory expected = new bytes4[](14);
        expected[0] = factory.addTicketAdmins.selector;
        expected[1] = factory.adminTicketData.selector;
        expected[2] = factory.adminTickets.selector;
        expected[3] = factory.allTicketData.selector;
        expected[4] = factory.createTicket.selector;
        expected[5] = factory.hostItTicketHash.selector;
        expected[6] = factory.mainAdminRole.selector;
        expected[7] = factory.removeTicketAdmins.selector;
        expected[8] = factory.ticketAdminRole.selector;
        expected[9] = factory.ticketCount.selector;
        expected[10] = factory.ticketData.selector;
        expected[11] = factory.ticketExists.selector;
        expected[12] = factory.ticketHash.selector;
        expected[13] = factory.updateTicket.selector;
        _assertExports(IFacet(address(factory)), expected);
    }

    function testExport_Marketplace() public view {
        bytes4[] memory expected = new bytes4[](25);
        expected[0] = marketplace.batchMintFiatTickets.selector;
        expected[1] = marketplace.batchRedeemFiatVouchers.selector;
        expected[2] = marketplace.claimRefund.selector;
        expected[3] = marketplace.feeEnabled.selector;
        expected[4] = marketplace.getAllFees.selector;
        expected[5] = marketplace.getFeeTokenAddress.selector;
        expected[6] = marketplace.getFiatDomainSeparator.selector;
        expected[7] = marketplace.getFiatVoucherTypehash.selector;
        expected[8] = marketplace.getHostItBalance.selector;
        expected[9] = marketplace.getHostItFee.selector;
        expected[10] = marketplace.getRefundPeriod.selector;
        expected[11] = marketplace.getTicketBalance.selector;
        expected[12] = marketplace.getTicketFee.selector;
        expected[13] = marketplace.getTicketFiatRevenue.selector;
        expected[14] = marketplace.getTrustedBackend.selector;
        expected[15] = marketplace.hashFiatVoucher.selector;
        expected[16] = marketplace.isFiatPaidToken.selector;
        expected[17] = marketplace.isFiatPaymentIdUsed.selector;
        expected[18] = marketplace.mintFiatTicket.selector;
        expected[19] = marketplace.mintTicket.selector;
        expected[20] = marketplace.redeemFiatVoucher.selector;
        expected[21] = marketplace.setTrustedBackend.selector;
        expected[22] = marketplace.updateTicketFees.selector;
        expected[23] = marketplace.withdrawHostItBalance.selector;
        expected[24] = marketplace.withdrawTicketBalance.selector;
        _assertExports(IFacet(address(marketplace)), expected);
    }

    function _assertExports(IFacet facet, bytes4[] memory expected) internal pure {
        bytes4[] memory got = Selectors.decode(facet.exportSelectors());
        assertEq(got.length, expected.length, "selector count mismatch");
        for (uint256 i; i < expected.length; ++i) {
            assertTrue(Utils.containsElement(got, expected[i]), "expected selector missing");
        }
        for (uint256 i; i < got.length; ++i) {
            assertTrue(Utils.containsElement(expected, got[i]), "unexpected selector present");
            assertTrue(got[i] != IFacet.exportSelectors.selector, "must exclude exportSelectors");
        }
    }
}
