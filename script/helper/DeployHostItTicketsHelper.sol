// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {FacetCut, FacetCutAction, DiamondArgs} from "@diamond-storage/DiamondStorage.sol";

abstract contract DeployHostItTicketsHelper is HelperContract, Context {
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

    function _createDiamondArgs(
        address _multiInit,
        address _erc165Init,
        address _hostItInit,
        address _ticketProxy,
        uint8[] memory _feeTypes,
        address[] memory _addresses
    ) internal view returns (DiamondArgs memory args_) {
        address[] memory initAddr = new address[](2);
        initAddr[0] = _erc165Init;
        initAddr[1] = _hostItInit;

        bytes[] memory initData = new bytes[](2);
        initData[0] = abi.encodeWithSignature("initErc165()");
        initData[1] =
            abi.encodeWithSignature("initHostIt(address,uint8[],address[])", _ticketProxy, _feeTypes, _addresses);

        // Prepare DiamondArgs: owner and init data
        args_ = DiamondArgs({
            owner: _msgSender(),
            init: _multiInit,
            initData: abi.encodeWithSignature("multiInit(address[],bytes[])", initAddr, initData)
        });
    }
}
