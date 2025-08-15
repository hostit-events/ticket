// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.marketplace.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant MARKETPLACE_STORAGE_LOCATION = 0x3f09c55b469305b27ecae2a46b3f364669f622316549d801837d9eeba9778d00;

struct MarketplaceStorage {
    mapping(uint40 => mapping(FeeType => bool)) feeEnabled;
    mapping(uint40 => mapping(FeeType => uint256)) ticketFee;
}

enum FeeType {
    ETH,
    WETH,
    USDT,
    USDC,
    EURC,
    USDT0,
    GHO,
    LINK,
    LSK,
    DISCOUNT
}
