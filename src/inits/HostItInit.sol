// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {LibFactory} from "@host-it/libs/LibFactory.sol";

event HostItInitialized();

contract HostItInit {
    function initHostIt(address _ticketImpl) external {
        LibFactory._factoryStorage().ticketImplementation = _ticketImpl;

        emit HostItInitialized();
    }
}
