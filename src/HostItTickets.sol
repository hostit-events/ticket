// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Diamond, FacetCut} from "@diamond/Diamond.sol";
import {AccessControlLib} from "@lattice/access/libraries/AccessControlLib.sol";

/*
⣾⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
⣿⣿⣿⣿⠉⠉⠹⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⡟⠉⠉⠉⢹⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠹⣿⣿⣿⣿⣧⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⠟⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣷⣦⣄⣀⣀⣀⣀⣀⣀⣀⣤⣶⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠿⠿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣷⣦⣄⣀⡀⠀⠀⠀⠀⠀⢀⣀⣤⣶⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠛⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⡿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠻⢿⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⢠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⠀⢀⣼⣿⣿⣿⣿⡿⠟⠉⠉⠀⠀⠀⠀⠈⠉⠙⠻⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⠀⠀⠀⣰⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⡇
⣿⣿⣿⣿⣄⣀⣰⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣷⣤⣤⣤⣸⣿⣿⣿⡇
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
⠻⠿⠿⠿⠿⠿⠿⠿⠿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠿⠿⠿⠿⠿⠿⠿⠿⠿⠃
*/

bytes32 constant INITIALIZER_ROLE = 0x00;

/// @title HostIt Tickets
/// @notice Implements ERC-2535 Diamond proxy pattern, allowing dynamic addition, replacement, and removal of facets
/// @author HostIt Protocol
contract HostItTickets is Diamond {
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

    receive() external payable override {
        assembly ("memory-safe") {
            mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
            revert(0x1c, 0x04)
        }
    }
}
