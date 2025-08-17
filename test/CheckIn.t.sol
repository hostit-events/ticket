// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {TicketData, FullTicketData} from "@host-it-storage/FactoryStorage.sol";
import {FeeType} from "@host-it-storage/MarketplaceStorage.sol";
import {DeployedHostIt} from "@host-it-test/states/DeployedHostIt.sol";

contract CheckInTest is DeployedHostIt {
    function setUp() public override {
        super.setUp();
        factoryFacet.createTicket(_getTicketData(), _getZeroFeeTypes(), _getZeroFees());
    }
}
