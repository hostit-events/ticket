// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FacetCut, FacetCutAction} from "@diamond-storage/DiamondStorage.sol";
import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {HostItTickets} from "@ticket/HostItTickets.sol";

abstract contract DeployHostItTicketsHelper is GetSelectors, Context {
    address constant DIAMOND_CUT_FACET = 0xD1AC537fBE953b0868a6ec93F025c4bB05E6D1AC;
    address constant DIAMOND_LOUPE_FACET = 0xD1A1C850E1ACd4ce10941e40eD67de60db56D1A1;
    address constant OWNABLE_ROLES_FACET = 0x020e74BCB4b03d5Fd1D163d7948D67Ccb7718020;
    address constant DIAMOND_INIT = 0xD1Ab4C0546Aaa0Bd9b0Fd73fEBa54D4Ca3038D1A;
    address constant HOST_IT_TICKETS = 0x4057170053DF6fA69C8579B71ce6288bd7cbA970;

    bytes32 constant DIAMOND_CUT_SALT = 0xdc6f5bb59963dc8b243ed7c696690110204d487b4ee1d4a8afeccc313ae170ab;
    bytes32 constant DIAMOND_LOUPE_SALT = 0x37a28ef414ff305b8d4c199c3da391e49c9e6a2522b7ac6aaeb5d7de9bb52807;
    bytes32 constant OWNABLE_ROLES_SALT = 0x6402e91caf86982f4453619c3082b298bb74cda45fad1dac35a1fdb9a29fa77f;
    bytes32 constant DIAMOND_INIT_SALT = 0x4b1f19753ac29403effac749761279f6c37238bc9b9706723d74fae2ba155961;
    bytes32 constant HOST_IT_SALT = 0xbc00dac142725ada40b30d71d8096ef44c311bbaed909e05e7a95a835b016769;

    function _getDiamondCutFacet() internal returns (address) {
        return
            DIAMOND_CUT_FACET.code.length == 0
                ? address(new DiamondCutFacet{salt: DIAMOND_CUT_SALT}())
                : DIAMOND_CUT_FACET;
    }

    function _getDiamondLoupeFacet() internal returns (address) {
        return DIAMOND_LOUPE_FACET.code.length == 0
            ? address(new DiamondLoupeFacet{salt: DIAMOND_LOUPE_SALT}())
            : DIAMOND_LOUPE_FACET;
    }

    function _getOwnableRolesFacet() internal returns (address) {
        return OWNABLE_ROLES_FACET.code.length == 0
            ? address(new OwnableRolesFacet{salt: OWNABLE_ROLES_SALT}())
            : OWNABLE_ROLES_FACET;
    }

    function _getDiamondInit() internal returns (address) {
        return DIAMOND_INIT.code.length == 0 ? address(new DiamondInit{salt: DIAMOND_INIT_SALT}()) : DIAMOND_INIT;
    }

    function _createInitFacetCuts(address _diamondCutFacet, address _diamondLoupeFacet, address _ownableRolesFacet)
        internal
        view
        returns (FacetCut[] memory cuts_)
    {
        cuts_ = new FacetCut[](3);

        cuts_[0] = FacetCut({
            facetAddress: _diamondCutFacet,
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondCutFacet")
        });

        cuts_[1] = FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondLoupeFacet")
        });

        cuts_[2] = FacetCut({
            facetAddress: _ownableRolesFacet,
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("OwnableRolesFacet")
        });
    }

    function _getHostItTickets() internal returns (address) {
        return HOST_IT_TICKETS.code.length == 0
            ? address(
                new HostItTickets{salt: HOST_IT_SALT}(
                    _createInitFacetCuts(_getDiamondCutFacet(), _getDiamondLoupeFacet(), _getOwnableRolesFacet()),
                    _getDiamondInit(),
                    abi.encodeWithSignature("initDiamond(address)", _msgSender())
                )
            )
            : HOST_IT_TICKETS;
    }

    function _createHostItFacetCuts(address _factoryFacet, address _marketplaceFacet, address _checkInFacet)
        internal
        view
        returns (FacetCut[] memory cuts_)
    {
        cuts_ = new FacetCut[](3);

        cuts_[0] = FacetCut({
            facetAddress: _factoryFacet, action: FacetCutAction.Add, functionSelectors: _getSelectors("FactoryFacet")
        });

        cuts_[1] = FacetCut({
            facetAddress: _marketplaceFacet,
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("MarketplaceFacet")
        });

        cuts_[2] = FacetCut({
            facetAddress: _checkInFacet, action: FacetCutAction.Add, functionSelectors: _getSelectors("CheckInFacet")
        });
    }
}
