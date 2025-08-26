// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

event CheckedIn(uint56 indexed ticketId, address indexed ticketOwner, uint256 tokenId);

event TicketAdminAdded(uint56 indexed ticketId, address indexed admin);

event TicketAdminRemoved(uint56 indexed ticketId, address indexed admin);
