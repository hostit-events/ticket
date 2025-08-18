// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant FACTORY_STORAGE_LOCATION = 0x610b7ed6689c503e651500bb8179583591f93afc835ec7dbed5872619168c100;

struct FactoryStorage {
    uint56 ticketId;
    address ticketImplementation;
    mapping(uint56 => ExtraTicketData) ticketIdToData;
    mapping(address => EnumerableSet.UintSet) adminTicketIds;
}

struct TicketData {
    uint40 startTime;
    uint40 endTime;
    uint40 purchaseStartTime;
    uint40 maxTickets;
    bool isFree;
    string name;
    string symbol;
    string uri;
}

struct ExtraTicketData {
    uint56 id;
    uint40 createdAt;
    uint40 updatedAt;
    uint40 startTime;
    uint40 endTime;
    uint40 purchaseStartTime;
    uint40 maxTickets;
    uint40 soldTickets;
    bool isFree;
    address ticketAdmin;
    address ticketAddress;
}

struct FullTicketData {
    uint56 id;
    uint40 createdAt;
    uint40 updatedAt;
    uint40 startTime;
    uint40 endTime;
    uint40 purchaseStartTime;
    uint40 maxTickets;
    uint40 soldTickets;
    bool isFree;
    address ticketAdmin;
    address ticketAddress;
    string name;
    string symbol;
    string uri;
}
