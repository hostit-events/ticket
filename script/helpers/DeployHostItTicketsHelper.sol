// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FacetCut, FacetCutAction} from "@diamond-storage/DiamondStorage.sol";
import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

abstract contract DeployHostItTicketsHelper is GetSelectors, Context {
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
