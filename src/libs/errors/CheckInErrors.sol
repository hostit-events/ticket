// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

error TicketUsePeriodNotStarted();
error TicketUsePeriodHasEnded();
error NotTicketOwner(uint256);
error AlreadyCheckedInForDay(uint8);
error NoAdmins();
error AddressZeroAdmin();
