// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant FACTORY_STORAGE_LOCATION = 0x610b7ed6689c503e651500bb8179583591f93afc835ec7dbed5872619168c100;

/// @title FactoryStorage
/// @notice Storage structure for managing factory data
/// @custom:storage-location erc7201:host.it.ticket.factory.storage
struct FactoryStorage {
    address ticketProxy;
    uint64 ticketId;
    mapping(uint64 => ExtraTicketData) ticketIdToData;
    mapping(address => EnumerableSet.UintSet) adminTicketIds;
}

/// @title TicketData
/// @notice Struct representing ticket data
struct TicketData {
    uint48 startTime;
    uint48 endTime;
    uint48 purchaseStartTime;
    uint40 maxTickets;
    uint8 maxTicketsPerUser;
    bool isFree;
    bool isRefundable;
    string name;
    string symbol;
    string uri;
}

/// @title ExtraTicketData
/// @notice Struct representing extra ticket data
struct ExtraTicketData {
    uint64 id;
    uint48 createdAt;
    uint48 updatedAt;
    uint48 startTime;
    uint48 endTime;
    uint48 purchaseStartTime;
    uint40 maxTickets;
    uint40 soldTickets;
    uint8 maxTicketsPerUser;
    bool isFree;
    bool isRefundable;
    address ticketAdmin;
    address ticketAddress;
}

/// @title FullTicketData
/// @notice Struct representing full ticket data
struct FullTicketData {
    uint64 id;
    uint48 createdAt;
    uint48 updatedAt;
    uint48 startTime;
    uint48 endTime;
    uint48 purchaseStartTime;
    uint40 maxTickets;
    uint40 soldTickets;
    uint8 maxTicketsPerUser;
    bool isFree;
    bool isRefundable;
    address ticketAdmin;
    address ticketAddress;
    string name;
    string symbol;
    string uri;
}
