// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {DeployHostItTicketsHelper} from "@ticket-script/helper/DeployHostItTicketsHelper.sol";
import {LibAddressesAndFees} from "@ticket-script/helper/LibAddressesAndFees.sol";
import {HostItTickets} from "@ticket/HostItTickets.sol";
import {CheckInFacet} from "@ticket/facets/CheckInFacet.sol";
import {FactoryFacet} from "@ticket/facets/FactoryFacet.sol";
import {MarketplaceFacet} from "@ticket/facets/MarketplaceFacet.sol";
import {HostItInit} from "@ticket/inits/HostItInit.sol";
import {Ticket} from "@ticket/libs/Ticket.sol";
import {TicketProxy} from "@ticket/libs/TicketProxy.sol";
import {Script} from "forge-std/Script.sol";

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
        address diamondInit = address(new DiamondInit());
        address hostItInit = address(new HostItInit());

        // Deploy Ticket Impl
        address ticketImpl = address(new Ticket());

        // Deploy Ticket Beacon
        address ticketBeacon = address(new UpgradeableBeacon(ticketImpl, _msgSender()));

        // Deploy Ticket Proxy
        address ticketProxy = address(new TicketProxy(ticketBeacon));

        // Get addresses and fees
        (address[] memory addresses, uint8[] memory feeTypes) =
            LibAddressesAndFees._getAddressesAndFeesByChainId(block.chainid);

        // Deploy HostItTickets diamond
        hostIt_ = address(
            new HostItTickets(
                _createFacetCuts(
                    diamondCutFacet, diamondLoupeFacet, ownableRolesFacet, factoryFacet, checkInFacet, marketplaceFacet
                ),
                multiInit,
                _createInitCalldata(diamondInit, hostItInit, ticketProxy, feeTypes, addresses)
            )
        );
        vm.stopBroadcast();
    }
}
