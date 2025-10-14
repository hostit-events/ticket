// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {LibFactory} from "@ticket/libs/LibFactory.sol";
import {LibMarketplace} from "@ticket/libs/LibMarketplace.sol";

event HostItInitialized();

contract HostItInit {
    function initHostIt(address _ticketProxy, FeeType[] calldata _feeTypes, address[] calldata _tokens) public {
        LibFactory._factoryStorage().ticketProxy = _ticketProxy;
        LibMarketplace._setFeeTokenAddresses(_feeTypes, _tokens);
        emit HostItInitialized();
    }
}
