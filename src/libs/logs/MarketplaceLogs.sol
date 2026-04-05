// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

event TicketFeeSet(uint64 indexed ticketId, FeeType[] feeType, uint256[] fee); // ticketId:{ticketId}, fee:{tok}

event TicketRefunded(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event HostItFeeBpsSet(uint16 indexed hostItFeeBps); // hostItFeeBps:BPS{1}

event TicketFeeAddressSet(FeeType[] feeType, address[] token); // token:{addr}

event TicketMinted(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, uint40 tokenId); // fee:{tok}, tokenId:{ticket}

event TicketBalanceWithdrawn(uint64 indexed ticketId, FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

event HostItBalanceWithdrawn(FeeType indexed feeType, uint256 fee, address indexed to); // fee:{tok}

error ContractNotAllowed();
