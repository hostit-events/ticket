// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FacetCut, FacetCutAction} from "@diamond-storage/DiamondStorage.sol";
import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

abstract contract DeployHostItTicketsHelper is GetSelectors, Context {
    function _createFacetCuts(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownableRolesFacet,
        address _factoryFacet,
        address _checkInFacet,
        address _marketplaceFacet
    ) internal view returns (FacetCut[] memory cuts_) {
        cuts_ = new FacetCut[](6);

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

        cuts_[3] = FacetCut({
            facetAddress: _factoryFacet, action: FacetCutAction.Add, functionSelectors: _getSelectors("FactoryFacet")
        });

        cuts_[4] = FacetCut({
            facetAddress: _checkInFacet, action: FacetCutAction.Add, functionSelectors: _getSelectors("CheckInFacet")
        });

        cuts_[5] = FacetCut({
            facetAddress: _marketplaceFacet,
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("MarketplaceFacet")
        });
    }

    function _createInitCalldata(
        address _diamondInit,
        address _hostItInit,
        address _ticketProxy,
        uint8[] memory _feeTypes,
        address[] memory _addresses
    ) internal view returns (bytes memory calldata_) {
        address[] memory initAddr = new address[](2);
        initAddr[0] = _diamondInit;
        initAddr[1] = _hostItInit;

        bytes[] memory initData = new bytes[](2);
        initData[0] = abi.encodeWithSignature("initDiamond(address)", _msgSender());
        initData[1] =
            abi.encodeWithSignature("initHostIt(address,uint8[],address[])", _ticketProxy, _feeTypes, _addresses);

        calldata_ = abi.encodeWithSignature("multiInit(address[],bytes[])", initAddr, initData);
    }
}
