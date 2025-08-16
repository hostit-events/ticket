// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {MarketplaceStorage, MARKETPLACE_STORAGE_LOCATION} from "@host-it-storage/MarketplaceStorage.sol";

library LibMarketplace {
    function _marketplaceStorage() internal pure returns (MarketplaceStorage storage mps_) {
        assembly {
            mps_.slot := MARKETPLACE_STORAGE_LOCATION
        }
    }
}
