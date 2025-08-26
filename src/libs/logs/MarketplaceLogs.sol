// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

event TicketFeeSet(uint56 indexed ticketId, FeeType indexed feeType, uint256 fee);

event TicketFeeAddressSet(FeeType indexed feeType, address indexed token);

event TicketMinted(uint56 indexed ticketId, FeeType indexed feeType, uint256 fee, uint40 tokenId);

event TicketBalanceWithdrawn(uint56 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to);

event HostItBalanceWithdrawn(FeeType indexed feeType, uint256 fee, address indexed to);
