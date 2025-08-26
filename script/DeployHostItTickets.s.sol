// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {FacetCut, FacetCutAction, DiamondArgs} from "@diamond-storage/DiamondStorage.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";
import {HostItInit} from "@ticket/inits/HostItInit.sol";
import {HostItTickets} from "@ticket/HostItTickets.sol";
import {FactoryFacet} from "@ticket/facets/FactoryFacet.sol";
import {CheckInFacet} from "@ticket/facets/CheckInFacet.sol";
import {MarketplaceFacet} from "@ticket/facets/MarketplaceFacet.sol";
import {Ticket} from "@ticket/Ticket.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {TokenAddresses} from "@ticket-script/helper/TokenAddresses.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract DeployHostItTickets is Script, HelperContract, Context {
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
                _createDiamondArgs(multiInit, erc165Init, hostItInit, ticketProxy)
            )
        );
        vm.stopBroadcast();
    }

    function _createFacetCuts(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownableRolesFacet,
        address _factoryFacet,
        address _checkInFacet,
        address _marketplaceFacet
    ) internal returns (FacetCut[] memory cuts_) {
        // Create an array of FacetCut entries for standard facets
        cuts_ = new FacetCut[](6);

        cuts_[0] = FacetCut({
            facetAddress: _diamondCutFacet,
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondCutFacet")
        });

        cuts_[1] = FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondLoupeFacet")
        });

        cuts_[2] = FacetCut({
            facetAddress: _ownableRolesFacet,
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("OwnableRolesFacet")
        });

        cuts_[3] = FacetCut({
            facetAddress: _factoryFacet,
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("FactoryFacet")
        });

        cuts_[4] = FacetCut({
            facetAddress: _checkInFacet,
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("CheckInFacet")
        });

        cuts_[5] = FacetCut({
            facetAddress: _marketplaceFacet,
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("MarketplaceFacet")
        });
    }

    function _createDiamondArgs(address _multiInit, address _erc165Init, address _hostItInit, address _ticketProxy)
        internal
        returns (DiamondArgs memory args_)
    {
        address[] memory initAddr = new address[](2);
        initAddr[0] = _erc165Init;
        initAddr[1] = _hostItInit;

        bytes[] memory initData = new bytes[](2);
        initData[0] = abi.encodeWithSignature("initErc165()");
        initData[1] = abi.encodeWithSignature(
            "initHostIt(address,uint8[],address[])",
            _ticketProxy,
            TokenAddresses._getMockFeeTypes(),
            TokenAddresses._getMockAddresses()
        );

        // Prepare DiamondArgs: owner and init data
        args_ = DiamondArgs({
            owner: _msgSender(),
            init: _multiInit,
            initData: abi.encodeWithSignature("multiInit(address[],bytes[])", initAddr, initData)
        });
    }
}
