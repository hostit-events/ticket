// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

event TicketFeeSet(uint64 indexed ticketId, FeeType[] feeType, uint256[] fee);

event TicketRefunded(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to);

event HostItFeeBpsSet(uint16 indexed hostItFeeBps);

event TicketFeeAddressSet(FeeType[] feeType, address[] token);

event TicketMinted(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, uint40 tokenId);

event TicketBalanceWithdrawn(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to);

event HostItBalanceWithdrawn(FeeType indexed feeType, uint256 fee, address indexed to);

error ContractNotAllowed();
