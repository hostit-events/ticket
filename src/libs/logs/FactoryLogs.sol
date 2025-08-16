// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ExtraTicketData} from "@host-it-storage/FactoryStorage.sol";

event TicketCreated(uint256 indexed ticketId, address indexed ticketAdmin, ExtraTicketData ticketData);

event TicketUpdated(uint256 indexed ticketId, address indexed ticketAdmin, ExtraTicketData ticketData);
