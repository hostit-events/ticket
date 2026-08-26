// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IFacet} from "@diamond/interfaces/IFacet.sol";
import {IFactory} from "@ticket/interfaces/IFactory.sol";
import {FactoryLib, FullTicketData, TicketData} from "@ticket/libs/FactoryLib.sol";
import {FeeType} from "@ticket/libs/MarketplaceLib.sol";

contract FactoryFacet is IFactory, IFacet {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @param _fees {tok} per-ticket prices in each fee token
    /// @return {ticketId}
    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external
        returns (uint64)
    {
        return FactoryLib.createTicket(_ticketData, _feeTypes, _fees);
    }

    /// @param _ticketId {ticketId}
    function updateTicket(TicketData calldata _ticketData, uint64 _ticketId) external {
        FactoryLib.updateTicket(_ticketData, _ticketId);
    }

    /// @param _ticketId {ticketId}
    function addTicketAdmins(uint64 _ticketId, address[] calldata _admins) external {
        FactoryLib.addTicketAdmins(_ticketId, _admins);
    }

    /// @param _ticketId {ticketId}
    function removeTicketAdmins(uint64 _ticketId, address[] calldata _admins) external {
        FactoryLib.removeTicketAdmins(_ticketId, _admins);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @return {ticketId} total ticket type count
    function ticketCount() public view returns (uint64) {
        return FactoryLib.getTicketCount();
    }

    /// @param _ticketId {ticketId}
    function ticketExists(uint64 _ticketId) public view returns (bool) {
        return FactoryLib.ticketExists(_ticketId);
    }

    /// @param _ticketId {ticketId}
    function ticketData(uint64 _ticketId) public view returns (FullTicketData memory) {
        return FactoryLib.getFullTicketData(_ticketId);
    }

    function allTicketData() public view returns (FullTicketData[] memory) {
        return FactoryLib.getAllFullTicketData();
    }

    /// @param _ticketAdmin {addr}
    function adminTickets(address _ticketAdmin) public view returns (uint64[] memory) {
        return FactoryLib.getAdminTicketIds(_ticketAdmin);
    }

    /// @param _ticketAdmin {addr}
    function adminTicketData(address _ticketAdmin) public view returns (FullTicketData[] memory) {
        return FactoryLib.getAdminFullTicketData(_ticketAdmin);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function hostItTicketHash() public pure returns (bytes32) {
        return FactoryLib.getHostItTicketHash();
    }

    /// @param _ticketId {ticketId}
    function ticketHash(uint64 _ticketId) public pure returns (bytes32) {
        return FactoryLib.generateTicketHash(_ticketId);
    }

    /// @param _ticketId {ticketId}
    function mainAdminRole(uint64 _ticketId) public pure returns (bytes32) {
        return FactoryLib.generateMainTicketAdminRole(_ticketId);
    }

    /// @param _ticketId {ticketId}
    function ticketAdminRole(uint64 _ticketId) public pure returns (bytes32) {
        return FactoryLib.generateTicketAdminRole(_ticketId);
    }

    function exportSelectors() external pure override returns (bytes memory selectors_) {
        selectors_ = abi.encodePacked(
            this.addTicketAdmins.selector,
            this.adminTicketData.selector,
            this.adminTickets.selector,
            this.allTicketData.selector,
            this.createTicket.selector,
            this.hostItTicketHash.selector,
            this.mainAdminRole.selector,
            this.removeTicketAdmins.selector,
            this.ticketAdminRole.selector,
            this.ticketCount.selector,
            this.ticketData.selector,
            this.ticketExists.selector,
            this.ticketHash.selector,
            this.updateTicket.selector
        );
    }
}
