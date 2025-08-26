// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {LibDiamond} from "@diamond/libraries/LibDiamond.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";
import {LibFactory} from "@ticket/libs/LibFactory.sol";
import {LibMarketplace} from "@ticket/libs/LibMarketplace.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

event HostItInitialized();

contract HostItInit {
    function initHostIt(address _ticketProxy, FeeType[] calldata _feeTypes, address[] calldata _tokens) public {
        LibDiamond._diamondStorage().supportedInterfaces[type(ITicket).interfaceId] = true;
        LibFactory._factoryStorage().ticketProxy = _ticketProxy;
        LibMarketplace._setFeeTokenAddresses(_feeTypes, _tokens);
        emit HostItInitialized();
    }
}
