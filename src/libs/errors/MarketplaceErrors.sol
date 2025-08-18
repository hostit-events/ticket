// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

error PurchaseTimeNotReached();
error TicketSoldOut();
error MaxTicketsHeld();
error TokenAddressZero();
error InvalidFeeConfig();
error FeeAlreadySet();
error ZeroFee();
error TicketIsFree();
error FeeNotEnabled();
error InsufficientBalance(address, FeeType, uint256);
error InsufficientAllowance(address, FeeType, uint256);
error WithdrawPeriodNotReached();
error InsufficientWithdrawBalance();
