// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {IFactory} from "@host-it/interfaces/IFactory.sol";
import {DeployHostIt} from "@host-it-script/DeployHostIt.s.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";

abstract contract DeployedHostIt is HelperContract {
    address public hostIt;
    DeployHostIt public deployHostIt;
    IFactory public factoryFacet;

    /// @notice Interface for the DiamondCut functionality of the deployed diamond.
    IDiamondCut public diamondCut;

    /// @notice Interface for the DiamondLoupe functionality of the deployed diamond.
    IDiamondLoupe public diamondLoupe;

    /// @notice Stores the facet addresses returned from the diamond loupe.
    address[] public facetAddresses;

    /// @notice List of facet contract names used in deployment.
    string[4] public facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnableRolesFacet", "FactoryFacet"];

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    /// @notice Deploys the Diamond contract and initializes interface references and facet addresses.
    /// @dev This function is intended to be called in a test setup phase (e.g., `setUp()` in Foundry).
    function setUp() public virtual {
        deployHostIt = new DeployHostIt();
        hostIt = deployHostIt.run();

        diamondCut = IDiamondCut(hostIt);
        diamondLoupe = IDiamondLoupe(hostIt);
        factoryFacet = IFactory(hostIt);

        facetAddresses = diamondLoupe.facetAddresses();
    }
}
