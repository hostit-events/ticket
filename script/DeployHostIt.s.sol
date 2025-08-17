// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {HostIt} from "@host-it/HostIt.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {FactoryFacet} from "@host-it/facets/FactoryFacet.sol";
import {CheckInFacet} from "@host-it/facets/CheckInFacet.sol";
// import {MarketplaceFacet} from "@host-it/facets/MarketplaceFacet.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {HostItInit} from "@host-it/inits/HostItInit.sol";
import {Ticket} from "@host-it/Ticket.sol";
import {FacetCut, FacetCutAction, DiamondArgs} from "@diamond-storage/DiamondStorage.sol";
import {LibContext} from "@host-it/libs/LibContext.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";

contract DeployHostIt is Script, HelperContract {
    function run() public returns (address hostIt_) {
        vm.startBroadcast();

        // Deploy facets
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnableRolesFacet ownableRolesFacet = new OwnableRolesFacet();
        FactoryFacet factoryFacet = new FactoryFacet();
        CheckInFacet checkInFacet = new CheckInFacet();
        // MarketplaceFacet marketplaceFacet = new MarketplaceFacet();

        // Deploy initializers
        MultiInit multiInit = new MultiInit();
        ERC165Init erc165Init = new ERC165Init();
        HostItInit hostItInit = new HostItInit();

        // Deploy Ticket Impl
        Ticket ticket = new Ticket();
        ticket.initialize(LibContext._msgSender(), "", "");

        address[] memory initAddr = new address[](2);
        bytes[] memory initData = new bytes[](2);

        initAddr[0] = address(erc165Init);
        initData[0] = abi.encodeWithSignature("initErc165()");

        initAddr[1] = address(hostItInit);
        initData[1] = abi.encodeWithSignature("initHostIt(address)", address(ticket));

        // Prepare DiamondArgs: owner and init data
        DiamondArgs memory args = DiamondArgs({
            owner: LibContext._msgSender(),
            init: address(multiInit),
            initData: abi.encodeWithSignature("multiInit(address[],bytes[])", initAddr, initData)
        });

        // Create an array of FacetCut entries for standard facets
        FacetCut[] memory cut = new FacetCut[](5);

        cut[0] = FacetCut({
            facetAddress: address(diamondCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondCutFacet")
        });

        cut[1] = FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondLoupeFacet")
        });

        cut[2] = FacetCut({
            facetAddress: address(ownableRolesFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("OwnableRolesFacet")
        });

        cut[3] = FacetCut({
            facetAddress: address(factoryFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("FactoryFacet")
        });

        cut[4] = FacetCut({
            facetAddress: address(checkInFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("CheckInFacet")
        });

        // Deploy HostIt diamond
        hostIt_ = address(new HostIt(cut, args));

        vm.stopBroadcast();
    }
}
