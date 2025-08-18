// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {IFactory} from "@ticket/interfaces/IFactory.sol";
import {ICheckIn} from "@ticket/interfaces/ICheckIn.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {TicketData} from "@ticket-storage/FactoryStorage.sol";
import {DeployHostItTickets} from "@ticket-script/DeployHostItTickets.s.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";

abstract contract DeployedHostItTickets is HelperContract {
    address public hostIt;
    DeployHostItTickets public deployHostItTickets;
    IFactory public factoryFacet;
    ICheckIn public checkInFacet;

    /// @notice Interface for the DiamondCut functionality of the deployed diamond.
    IDiamondCut public diamondCut;

    /// @notice Interface for the DiamondLoupe functionality of the deployed diamond.
    IDiamondLoupe public diamondLoupe;

    /// @notice Stores the facet addresses returned from the diamond loupe.
    address[] public facetAddresses;

    /// @notice List of facet contract names used in deployment.
    string[5] public facetNames =
        ["DiamondCutFacet", "DiamondLoupeFacet", "OwnableRolesFacet", "FactoryFacet", "CheckInFacet"];

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint40 public _currentTime = uint40(block.timestamp);

    /// @notice Deploys the Diamond contract and initializes interface references and facet addresses.
    /// @dev This function is intended to be called in a test setup phase (e.g., `setUp()` in Foundry).
    function setUp() public virtual {
        deployHostItTickets = new DeployHostItTickets();
        hostIt = deployHostItTickets.run();

        diamondCut = IDiamondCut(hostIt);
        diamondLoupe = IDiamondLoupe(hostIt);
        factoryFacet = IFactory(hostIt);
        checkInFacet = ICheckIn(hostIt);

        facetAddresses = diamondLoupe.facetAddresses();
    }

    function _getTicketData() internal view returns (TicketData memory ticketData_) {
        ticketData_ = TicketData({
            startTime: uint40(block.timestamp + 1 days),
            endTime: uint40(block.timestamp + 2 days),
            purchaseStartTime: _currentTime,
            maxTickets: 100,
            isFree: true,
            name: "Test Ticket",
            symbol: "",
            uri: "ipfs://"
        });
    }

    function _getUpdatedTicketData() internal view returns (TicketData memory ticketData_) {
        ticketData_ = TicketData({
            startTime: uint40(block.timestamp + 1 days),
            endTime: uint40(block.timestamp + 2 days),
            purchaseStartTime: _currentTime,
            maxTickets: 100,
            isFree: true,
            name: "Test Ticket Update",
            symbol: "TTU",
            uri: "ipfs://2"
        });
    }

    function _getZeroFeeTypes() internal pure returns (FeeType[] memory feeTypes_) {
        feeTypes_ = new FeeType[](0);
    }

    function _getZeroFees() internal pure returns (uint256[] memory fees_) {
        fees_ = new uint256[](0);
    }
}
