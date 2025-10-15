// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

event CheckedIn(uint64 indexed ticketId, address indexed ticketOwner, uint40 tokenId);

event TicketAdminAdded(uint64 indexed ticketId, address indexed admin);

event TicketAdminRemoved(uint64 indexed ticketId, address indexed admin);
