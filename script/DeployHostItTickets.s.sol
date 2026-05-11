// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {AddressesAndFees} from "@ticket-script/helpers/AddressesAndFees.sol";
import {DeployHostItTicketsHelper} from "@ticket-script/helpers/DeployHostItTicketsHelper.sol";
import {HostItInit} from "@ticket/inits/HostItInit.sol";
import {Script} from "forge-std/Script.sol";

contract DeployHostItTickets is Script, DeployHostItTicketsHelper {
    function run() public returns (address hostIt_) {
        vm.startBroadcast();

        // Deploy HostItTickets diamond
        hostIt_ = _getHostItTickets();

        vm.stopBroadcast();
    }
}
