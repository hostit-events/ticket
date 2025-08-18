// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketData, FullTicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {DeployedHostItTickets} from "@ticket-test/states/DeployedHostItTickets.sol";

contract CheckInTest is DeployedHostItTickets {
    function setUp() public override {
        super.setUp();
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
    }
}
