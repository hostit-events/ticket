// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@host-it-storage/MarketplaceStorage.sol";

error EmptyName();
error EmptyURI();
error StartTimeShouldBeAhead();
error EndTimeShouldBeOneDayAfterStartTime();
error PurchaseStartTimeShouldBeOneDayBeforeStartTime();
error MaxTicketsIsZero();
error ArrayMismatch();
error FeeAlreadySet(FeeType);
error ZeroFee(FeeType);
error TicketDoesNotExist(uint56);
error TicketUseHasCommenced();
error MaxTicketsShouldEqualSupply();
error TicketImplementationNotSet();
