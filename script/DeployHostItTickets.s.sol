// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {HostItInit} from "@ticket/inits/HostItInit.sol";
import {HostItTickets} from "@ticket/HostItTickets.sol";
import {FactoryFacet} from "@ticket/facets/FactoryFacet.sol";
import {CheckInFacet} from "@ticket/facets/CheckInFacet.sol";
import {MarketplaceFacet} from "@ticket/facets/MarketplaceFacet.sol";
import {Ticket} from "@ticket/Ticket.sol";
import {AddressesAndFees} from "@ticket-script/helper/AddressesAndFees.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {DeployHostItTicketsHelper} from "@ticket-script/helper/DeployHostItTicketsHelper.sol";

contract DeployHostItTicketsTest is Script, DeployHostItTicketsHelper {
    function run() public returns (address hostIt_) {
        vm.startBroadcast();
        // Deploy facets
        address diamondCutFacet = address(new DiamondCutFacet());
        address diamondLoupeFacet = address(new DiamondLoupeFacet());
        address ownableRolesFacet = address(new OwnableRolesFacet());
        address factoryFacet = address(new FactoryFacet());
        address checkInFacet = address(new CheckInFacet());
        address marketplaceFacet = address(new MarketplaceFacet());

        // Deploy initializers
        address multiInit = address(new MultiInit());
        address erc165Init = address(new ERC165Init());
        address hostItInit = address(new HostItInit());

        // Deploy Ticket Impl
        address ticketImpl = address(new Ticket());

        // Deploy Ticket Beacon
        address ticketBeacon = address(new UpgradeableBeacon(ticketImpl, _msgSender()));

        // Deploy Ticket Proxy
        address ticketProxy = address(new BeaconProxy(ticketBeacon, ""));

        // Deploy HostItTickets diamond
        hostIt_ = address(
            new HostItTickets(
                _createFacetCuts(
                    diamondCutFacet, diamondLoupeFacet, ownableRolesFacet, factoryFacet, checkInFacet, marketplaceFacet
                ),
                _createDiamondArgs(
                    multiInit,
                    erc165Init,
                    hostItInit,
                    ticketProxy,
                    AddressesAndFees._getMockFeeTypes(),
                    AddressesAndFees._getMockAddresses()
                )
            )
        );
        vm.stopBroadcast();
    }
}
