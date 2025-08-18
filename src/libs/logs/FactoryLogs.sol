// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {ExtraTicketData} from "@ticket-storage/FactoryStorage.sol";

event TicketCreated(uint56 indexed ticketId, address indexed ticketAdmin, ExtraTicketData ticketData);

event TicketUpdated(uint56 indexed ticketId, address indexed ticketAdmin, ExtraTicketData ticketData);
