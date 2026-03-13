// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {DeployHostItTicketsHelper} from "@ticket-script/helpers/DeployHostItTicketsHelper.sol";
import {LibAddressesAndFees} from "@ticket-script/helpers/LibAddressesAndFees.sol";
import {HostItTickets} from "@ticket/HostItTickets.sol";
import {CheckInFacet} from "@ticket/facets/CheckInFacet.sol";
import {FactoryFacet} from "@ticket/facets/FactoryFacet.sol";
import {MarketplaceFacet} from "@ticket/facets/MarketplaceFacet.sol";
import {HostItInit} from "@ticket/inits/HostItInit.sol";
import {Ticket} from "@ticket/libs/Ticket.sol";
import {TicketProxy} from "@ticket/libs/TicketProxy.sol";
import {Script} from "forge-std/Script.sol";

contract DeployHostItTickets is Script, DeployHostItTicketsHelper {
    function run() public returns (address hostIt_) {
        vm.startBroadcast();

        // Deploy HostItTickets diamond
        hostIt_ = _getHostItTickets();

        address factoryFacet = address(new FactoryFacet());
        address marketplaceFacet = address(new MarketplaceFacet());
        address checkInFacet = address(new CheckInFacet());

        // Deploy initializer
        address hostItInit = address(new HostItInit());

        // Deploy Ticket Impl
        address ticketImpl = address(new Ticket());

        // Deploy Ticket Beacon
        address ticketBeacon = address(new UpgradeableBeacon(ticketImpl, hostIt_));

        // Deploy Ticket Proxy
        address ticketProxy = address(new TicketProxy(ticketBeacon));

        // Get addresses and fees
        (address[] memory addresses, uint8[] memory feeTypes) =
            LibAddressesAndFees._getAddressesAndFeesByChainId(block.chainid);

        // Initialize HostItTickets
        IDiamondCut(hostIt_)
            .diamondCut(
                _createHostItFacetCuts(factoryFacet, marketplaceFacet, checkInFacet),
                hostItInit,
                abi.encodeWithSelector(HostItInit.initHostIt.selector, ticketProxy, feeTypes, addresses)
            );

        vm.stopBroadcast();
    }
}
