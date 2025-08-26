// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {IFactory} from "@ticket/interfaces/IFactory.sol";
import {ICheckIn} from "@ticket/interfaces/ICheckIn.sol";
import {IMarketplace} from "@ticket/interfaces/IMarketplace.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {TicketData} from "@ticket-storage/FactoryStorage.sol";
import {DeployHostItTickets} from "@ticket-script/DeployHostItTickets.s.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@ticket-logs/MarketplaceLogs.sol";

abstract contract DeployedHostItTickets is HelperContract {
    address public hostIt;
    DeployHostItTickets public deployHostItTickets;
    IFactory public factoryFacet;
    ICheckIn public checkInFacet;
    IMarketplace public marketplaceFacet;

    /// @notice Interface for the DiamondCut functionality of the deployed diamond.
    IDiamondCut public diamondCut;

    /// @notice Interface for the DiamondLoupe functionality of the deployed diamond.
    IDiamondLoupe public diamondLoupe;

    /// @notice Stores the facet addresses returned from the diamond loupe.
    address[] public facetAddresses;

    /// @notice List of facet contract names used in deployment.
    string[6] public facetNames = [
        "DiamondCutFacet",
        "DiamondLoupeFacet",
        "OwnableRolesFacet",
        "FactoryFacet",
        "CheckInFacet",
        "MarketplaceFacet"
    ];

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address withdrawer = makeAddr("withdrawer");

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
        marketplaceFacet = IMarketplace(hostIt);

        facetAddresses = diamondLoupe.facetAddresses();
    }

    function _createFreeTicket() internal {
        factoryFacet.createTicket(_getFreeTicketData(), _getZeroFeeType(), _getZeroFee());
    }

    function _updateFreeTicket(uint40 _ticketId) internal {
        factoryFacet.updateTicket(_getFreeUpdatedTicketData(), _ticketId);
    }

    function _createPaidTicket() internal {
        factoryFacet.createTicket(_getPaidTicketData(), _getFeeTypes(), _getFees());
    }

    function _updatePaidTicket(uint40 _ticketId) internal {
        factoryFacet.updateTicket(_getPaidUpdatedTicketData(), _ticketId);
    }

    function _mintTicketFree() internal returns (uint56 ticketId_, uint40 tokenId_) {
        _createFreeTicket();
        ticketId_ = factoryFacet.ticketCount();
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId_, FeeType.NONE, 0, 1);
        tokenId_ = marketplaceFacet.mintTicket(ticketId_, FeeType.NONE, alice);
    }

    function _mintTicketETH() internal returns (uint56 ticketId_, uint40 tokenId_, uint256 fee_, uint256 hostItFee_) {
        _createPaidTicket();
        ticketId_ = factoryFacet.ticketCount();
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId_, FeeType.ETH);
        hoax(alice, totalFee);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId_, FeeType.ETH, totalFee, 1);
        (bool success, bytes memory result) = address(marketplaceFacet).call{value: totalFee}(
            abi.encodeWithSelector(marketplaceFacet.mintTicket.selector, ticketId_, FeeType.ETH, alice)
        );
        assertTrue(success);
        tokenId_ = abi.decode(result, (uint40));
        fee_ = fee;
        hostItFee_ = hostItFee;
    }

    function _mintTicketUSDT()
        internal
        returns (uint56 ticketId_, uint40 tokenId_, uint256 fee_, uint256 hostItFee_, ERC20Mock usdt_)
    {
        _createPaidTicket();
        ticketId_ = factoryFacet.ticketCount();
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId_, FeeType.USDT);
        usdt_ = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDT));
        usdt_.mint(alice, totalFee);
        vm.prank(alice);
        usdt_.approve(address(marketplaceFacet), totalFee);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId_, FeeType.USDT, totalFee, 1);
        tokenId_ = marketplaceFacet.mintTicket(ticketId_, FeeType.USDT, alice);
        fee_ = fee;
        hostItFee_ = hostItFee;
    }

    function _mintTicketUSDC()
        internal
        returns (uint56 ticketId_, uint40 tokenId_, uint256 fee_, uint256 hostItFee_, ERC20Mock usdc_)
    {
        _createPaidTicket();
        ticketId_ = factoryFacet.ticketCount();
        (uint256 fee, uint256 hostItFee, uint256 totalFee) = marketplaceFacet.getAllFees(ticketId_, FeeType.USDC);
        usdc_ = ERC20Mock(marketplaceFacet.getFeeTokenAddress(FeeType.USDC));
        usdc_.mint(alice, totalFee);
        vm.prank(alice);
        usdc_.approve(address(marketplaceFacet), totalFee);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, hostIt);
        emit TicketMinted(ticketId_, FeeType.USDC, totalFee, 1);
        tokenId_ = marketplaceFacet.mintTicket(ticketId_, FeeType.USDC, alice);
        fee_ = fee;
        hostItFee_ = hostItFee;
    }

    function _getFreeTicketData() internal view returns (TicketData memory ticketData_) {
        ticketData_ = TicketData({
            startTime: uint40(block.timestamp + 1 days),
            endTime: uint40(block.timestamp + 2 days),
            purchaseStartTime: _currentTime,
            maxTickets: type(uint40).max,
            isFree: true,
            name: "Free Ticket",
            symbol: "",
            uri: "ipfs://"
        });
    }

    function _getFreeUpdatedTicketData() internal view returns (TicketData memory ticketData_) {
        ticketData_ = TicketData({
            startTime: uint40(block.timestamp + 1 days),
            endTime: uint40(block.timestamp + 2 days),
            purchaseStartTime: _currentTime,
            maxTickets: 100,
            isFree: true,
            name: "Updated Free Ticket",
            symbol: "UFT",
            uri: "ipfs://2"
        });
    }

    function _getPaidTicketData() internal view returns (TicketData memory ticketData_) {
        ticketData_ = TicketData({
            startTime: uint40(block.timestamp + 1 days),
            endTime: uint40(block.timestamp + 2 days),
            purchaseStartTime: _currentTime,
            maxTickets: type(uint40).max,
            isFree: false,
            name: "Paid Ticket",
            symbol: "",
            uri: "ipfs://$"
        });
    }

    function _getPaidUpdatedTicketData() internal view returns (TicketData memory ticketData_) {
        ticketData_ = TicketData({
            startTime: uint40(block.timestamp + 1 days),
            endTime: uint40(block.timestamp + 2 days),
            purchaseStartTime: _currentTime,
            maxTickets: type(uint40).max,
            isFree: false,
            name: "Updated Paid Ticket",
            symbol: "UPT",
            uri: "ipfs://$$"
        });
    }

    function _getZeroFeeType() internal pure returns (FeeType[] memory feeTypes_) {
        feeTypes_ = new FeeType[](0);
    }

    function _getZeroFee() internal pure returns (uint256[] memory fees_) {
        fees_ = new uint256[](0);
    }

    function _getFeeTypes() internal pure returns (FeeType[] memory feeTypes_) {
        feeTypes_ = new FeeType[](3);
        feeTypes_[0] = FeeType.ETH;
        feeTypes_[1] = FeeType.USDT;
        feeTypes_[2] = FeeType.USDC;
    }

    function _getFees() internal pure returns (uint256[] memory fees_) {
        fees_ = new uint256[](3);
        fees_[0] = 25e14;
        fees_[1] = 10e18;
        fees_[2] = 10e6;
    }
}
