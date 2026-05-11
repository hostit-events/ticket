// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {AccessControlLib} from "@lattice/access/libraries/AccessControlLib.sol";
import {FactoryLib} from "@ticket/libs/FactoryLib.sol";
import {FeeType} from "@ticket/libs/MarketplaceLib.sol";
import {MarketplaceLib} from "@ticket/libs/MarketplaceLib.sol";

event HostItInitialized(address ticketProxy, FeeType[] feeTypes, address[] tokens);

contract HostItInit {
    /// @param _admin {addr} ticket implementation proxy
    /// @param _ticketProxy {addr} ticket implementation proxy
    /// @param _tokens {addr} ERC20 token addresses for each fee type
    function initHostIt(address _admin, address _ticketProxy, FeeType[] calldata _feeTypes, address[] calldata _tokens)
        public
    {
        AccessControlLib.__AccessControl_init(_admin);
        FactoryLib.factoryStorage().ticketProxy = _ticketProxy;
        MarketplaceLib._setFeeTokenAddresses(_feeTypes, _tokens);
        emit HostItInitialized(_ticketProxy, _feeTypes, _tokens);
    }
}
