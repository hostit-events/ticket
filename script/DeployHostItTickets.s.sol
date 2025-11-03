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

contract DeployHostItTicketsTest is Script, DeployHostItTicketsHelper {
    function run() public returns (address hostIt_) {
        vm.startBroadcast();
        // Facets
        address diamondCutFacet = address(new DiamondCutFacet{salt: vm.envBytes32("DIAMOND_CUT_SALT")}());
        address diamondLoupeFacet = address(new DiamondLoupeFacet{salt: vm.envBytes32("DIAMOND_LOUPE_SALT")}());
        address ownableRolesFacet = address(new OwnableRolesFacet{salt: vm.envBytes32("OWNABLE_ROLES_SALT")}());

        // Initializer
        address diamondInit = address(new DiamondInit{salt: vm.envBytes32("DIAMOND_INIT_SALT")}());

        // Deploy HostItTickets diamond
        hostIt_ = address(
            new HostItTickets{salt: vm.envBytes32("HOST_IT_SALT")}(
                _createInitFacetCuts(diamondCutFacet, diamondLoupeFacet, ownableRolesFacet),
                diamondInit,
                abi.encodeWithSignature("initDiamond(address)", _msgSender())
            )
        );
        vm.stopBroadcast();
    }

    function init(address _hostIt) public {
        vm.startBroadcast();
        address factoryFacet = address(new FactoryFacet());
        address marketplaceFacet = address(new MarketplaceFacet());
        address checkInFacet = address(new CheckInFacet());

        // Deploy initializer
        address hostItInit = address(new HostItInit());
        // Deploy Ticket Impl
        address ticketImpl = address(new Ticket());

        // Deploy Ticket Beacon
        address ticketBeacon = address(new UpgradeableBeacon(ticketImpl, _hostIt));

        // Deploy Ticket Proxy
        address ticketProxy = address(new TicketProxy(ticketBeacon));

        // Get addresses and fees
        (address[] memory addresses, uint8[] memory feeTypes) =
            LibAddressesAndFees._getAddressesAndFeesByChainId(block.chainid);

        // Initialize HostItTickets
        IDiamondCut(_hostIt)
            .diamondCut(
                _createHostItFacetCuts(factoryFacet, marketplaceFacet, checkInFacet),
                hostItInit,
                abi.encodeWithSelector(HostItInit.initHostIt.selector, ticketProxy, feeTypes, addresses)
            );
        vm.stopBroadcast();
    }
}
