// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {FacetCut, Lattice} from "@lattice/Lattice.sol";
import {AccessControlLib} from "@lattice/access/libraries/AccessControlLib.sol";

/*
⣾⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⠉⠉⠹⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⡟⠉⠉⠉⢹⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠹⣿⣿⣿⣿⣧⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⠟⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣷⣦⣄⣀⣀⣀⣀⣀⣀⣀⣤⣶⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠿⠿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣷⣦⣄⣀⡀⠀⠀⠀⠀⠀⢀⣀⣤⣶⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠛⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⡿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠻⢿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⢠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⠀⢀⣼⣿⣿⣿⣿⡿⠟⠉⠉⠀⠀⠀⠀⠈⠉⠙⠻⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⠀⠀⠀⣰⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿
⣿⣿⣿⣿⣄⣀⣰⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣷⣤⣤⣤⣸⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠻⠿⠿⠿⠿⠿⠿⠿⠿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠿⠿⠿⠿⠿⠿⠿⠿⠃
*/

// keccak256("host.it.tickets.initializer")
bytes32 constant INITIALIZER_ROLE = 0x8bee2586c5e3fefa3b170e4d771ec5051c21576e1f631a6fb7cebb1c8696086a;

/// @title HostIt Tickets
/// @notice Implements ERC-2535 Diamond proxy pattern, allowing dynamic addition, replacement, and removal of facets
/// @author HostIt Protocol
contract HostItTickets is Lattice {
    constructor(address _init) {
        AccessControlLib._grantRole(INITIALIZER_ROLE, _init);
    }

    function initialize(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata)
        public
        payable
        override
    {
        AccessControlLib.checkRole(INITIALIZER_ROLE);
        super.initialize(_facetCuts, _init, _calldata);
    }
}
