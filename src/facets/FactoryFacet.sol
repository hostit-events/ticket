// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {LibFactory} from "@host-it/libs/LibFactory.sol";
import {TicketData, FullTicketData} from "@host-it-storage/FactoryStorage.sol";
import {FeeType} from "@host-it-storage/MarketplaceStorage.sol";

contract FactoryFacet {
    using LibFactory for *;

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function createTicket(TicketData calldata _ticketData, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external
    {
        _ticketData._createTicket(_feeTypes, _fees);
    }

    function updateTicket(TicketData calldata _ticketData, uint56 _ticketId) external {
        _ticketData._updateTicket(_ticketId);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function ticketCount() public view returns (uint56) {
        return LibFactory._getTicketCount();
    }

    function ticketExists(uint56 _ticketId) public view returns (bool) {
        return _ticketId._ticketExists();
    }

    function ticketData(uint56 _ticketId) public view returns (FullTicketData memory) {
        return _ticketId._getFullTicketData();
    }

    function allTicketData() public view returns (FullTicketData[] memory) {
        return LibFactory._getAllFullTicketData();
    }

    function adminTickets(address _ticketAdmin) public view returns (uint56[] memory) {
        return _ticketAdmin._getAdminTicketIds();
    }

    function adminTicketData(address _ticketAdmin) public view returns (FullTicketData[] memory) {
        return _ticketAdmin._getAdminFullTicketData();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function hostItTicketHash() public pure returns (bytes32) {
        return LibFactory._getHostItTicketHash();
    }

    function ticketHash(uint56 _ticketId) public pure returns (bytes32) {
        return _ticketId._generateTicketHash();
    }

    function mainAdminRole(uint56 _ticketId) public pure returns (uint256) {
        return _ticketId._generateMainTicketAdminRole();
    }

    function ticketAdminRole(uint56 _ticketId) public pure returns (uint256) {
        return _ticketId._generateTicketAdminRole();
    }
}
