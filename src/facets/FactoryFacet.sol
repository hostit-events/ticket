// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FullTicketData, TicketData} from "@ticket-storage/FactoryStorage.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";
import {IFactory} from "@ticket/interfaces/IFactory.sol";
import {LibFactory} from "@ticket/libs/LibFactory.sol";

contract FactoryFacet is IFactory {
    using LibFactory for *;

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @param _fees {tok} per-ticket prices in each fee token
    /// @return {ticketId}
    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external
        returns (uint64)
    {
        return _ticketData._createTicket(_feeTypes, _fees);
    }

    /// @param _ticketId {ticketId}
    function updateTicket(TicketData calldata _ticketData, uint64 _ticketId) external {
        _ticketData._updateTicket(_ticketId);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @return {ticketId} total ticket type count
    function ticketCount() public view returns (uint64) {
        return LibFactory._getTicketCount();
    }

    /// @param _ticketId {ticketId}
    function ticketExists(uint64 _ticketId) public view returns (bool) {
        return _ticketId._ticketExists();
    }

    /// @param _ticketId {ticketId}
    function ticketData(uint64 _ticketId) public view returns (FullTicketData memory) {
        return _ticketId._getFullTicketData();
    }

    function allTicketData() public view returns (FullTicketData[] memory) {
        return LibFactory._getAllFullTicketData();
    }

    /// @param _ticketAdmin {addr}
    function adminTickets(address _ticketAdmin) public view returns (uint64[] memory) {
        return _ticketAdmin._getAdminTicketIds();
    }

    /// @param _ticketAdmin {addr}
    function adminTicketData(address _ticketAdmin) public view returns (FullTicketData[] memory) {
        return _ticketAdmin._getAdminFullTicketData();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function hostItTicketHash() public pure returns (bytes32) {
        return LibFactory._getHostItTicketHash();
    }

    /// @param _ticketId {ticketId}
    function ticketHash(uint64 _ticketId) public pure returns (bytes32) {
        return _ticketId._generateTicketHash();
    }

    /// @param _ticketId {ticketId}
    function mainAdminRole(uint64 _ticketId) public pure returns (uint256) {
        return _ticketId._generateMainTicketAdminRole();
    }

    /// @param _ticketId {ticketId}
    function ticketAdminRole(uint64 _ticketId) public pure returns (uint256) {
        return _ticketId._generateTicketAdminRole();
    }
}
