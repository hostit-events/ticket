// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableFacet} from "@diamond/facets/OwnableFacet.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {FacetCut, FacetCutAction} from "@diamond/libraries/DiamondLib.sol";
import {AccessControl} from "@lattice/access/AccessControl.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {AddressesAndFees} from "@ticket-script/helpers/AddressesAndFees.sol";
import {HostItTickets} from "@ticket/HostItTickets.sol";
import {CheckInFacet} from "@ticket/facets/CheckInFacet.sol";
import {FactoryFacet} from "@ticket/facets/FactoryFacet.sol";
import {MarketplaceFacet} from "@ticket/facets/MarketplaceFacet.sol";
import {HostItInit} from "@ticket/inits/HostItInit.sol";
import {Ticket} from "@ticket/libs/Ticket.sol";

abstract contract DeployHostItTicketsHelper is GetSelectors, Context {
    // address constant DIAMOND_CUT_FACET = 0xD1AC537fBE953b0868a6ec93F025c4bB05E6D1AC;
    // address constant DIAMOND_LOUPE_FACET = 0xD1A1C850E1ACd4ce10941e40eD67de60db56D1A1;
    // address constant OWNABLE_FACET = 0x020e74BCB4b03d5Fd1D163d7948D67Ccb7718020;
    // address constant DIAMOND_INIT = 0xD1Ab4C0546Aaa0Bd9b0Fd73fEBa54D4Ca3038D1A;
    // address payable constant HOST_IT_TICKETS = payable(0x4057170053DF6fA69C8579B71ce6288bd7cbA970);

    bytes32 constant DIAMOND_CUT_SALT = 0xdc6f5bb59963dc8b243ed7c696690110204d487b4ee1d4a8afeccc313ae170ab;
    bytes32 constant DIAMOND_LOUPE_SALT = 0x37a28ef414ff305b8d4c199c3da391e49c9e6a2522b7ac6aaeb5d7de9bb52807;
    bytes32 constant OWNABLE_SALT = 0x6402e91caf86982f4453619c3082b298bb74cda45fad1dac35a1fdb9a29fa77f;
    bytes32 constant DIAMOND_INIT_SALT = 0x4b1f19753ac29403effac749761279f6c37238bc9b9706723d74fae2ba155961;
    bytes32 constant HOST_IT_SALT = 0xbc00dac142725ada40b30d71d8096ef44c311bbaed909e05e7a95a835b016769;

    function _getDiamondCutFacet() internal returns (address) {
        return
        // DIAMOND_CUT_FACET.code.length == 0 ?
        address(new DiamondCutFacet());
        // : DIAMOND_CUT_FACET;
    }

    function _getDiamondLoupeFacet() internal returns (address) {
        return
        // DIAMOND_LOUPE_FACET.code.length == 0 ?
        address(new DiamondLoupeFacet());
        // : DIAMOND_LOUPE_FACET;
    }

    function _getOwnableFacet() internal returns (address) {
        return
        // OWNABLE_FACET.code.length == 0 ?
        address(new OwnableFacet());
        // : OWNABLE_FACET;
    }

    function _getAccessControlFacet() internal returns (address) {
        return address(new AccessControl());
    }

    function _getFactoryFacet() internal returns (address) {
        return address(new FactoryFacet());
    }

    function _getMarketplaceFacet() internal returns (address) {
        return address(new MarketplaceFacet());
    }

    function _getCheckInFacet() internal returns (address) {
        return address(new CheckInFacet());
    }

    function _getMultiInit() internal returns (address) {
        return address(new MultiInit());
    }

    function _getDiamondInit() internal returns (address) {
        return
        // DIAMOND_INIT.code.length == 0 ?
        address(new DiamondInit());
        //  : DIAMOND_INIT;
    }

    function _getHostItInit() internal returns (address) {
        return address(new HostItInit());
    }

    function _getTicketImpl() internal returns (address) {
        return address(new Ticket());
    }

    function _createFacetCuts() internal returns (FacetCut[] memory cuts_) {
        cuts_ = new FacetCut[](7);

        cuts_[0] = FacetCut({
            facetAddress: _getDiamondCutFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondCutFacet")
        });

        cuts_[1] = FacetCut({
            facetAddress: _getDiamondLoupeFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondLoupeFacet")
        });

        cuts_[2] = FacetCut({
            facetAddress: _getOwnableFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("OwnableFacet")
        });

        cuts_[3] = FacetCut({
            facetAddress: _getAccessControlFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControl")
        });

        cuts_[4] = FacetCut({
            facetAddress: _getFactoryFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("FactoryFacet")
        });

        cuts_[5] = FacetCut({
            facetAddress: _getMarketplaceFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("MarketplaceFacet")
        });

        cuts_[6] = FacetCut({
            facetAddress: _getCheckInFacet(),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("CheckInFacet")
        });
    }

    function _getMultiInitCalldata() internal returns (bytes memory) {
        address[] memory initAddresses = new address[](2);
        bytes[] memory initCalldatas = new bytes[](2);

        initAddresses[0] = _getDiamondInit();
        initAddresses[1] = _getHostItInit();

        initCalldatas[0] = abi.encodeWithSignature("init(address)", _msgSender());
        (uint8[] memory feeTypes, address[] memory addresses) = AddressesAndFees.byChainId(block.chainid);
        initCalldatas[1] = abi.encodeWithSignature(
            "initHostIt(address,address,uint8[],address[])", _msgSender(), _getTicketImpl(), feeTypes, addresses
        );

        return abi.encodeWithSignature("multiInit(address[],bytes[])", initAddresses, initCalldatas);
    }

    function _getHostItTickets() internal returns (address ticket_) {
        ticket_ =
        // HOST_IT_TICKETS.code.length == 0 ?
        address(new HostItTickets(tx.origin));
        // : HOST_IT_TICKETS;
        HostItTickets(payable(ticket_)).initialize(_createFacetCuts(), _getMultiInit(), _getMultiInitCalldata());
    }
}
