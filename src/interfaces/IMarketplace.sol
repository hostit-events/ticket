// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

/// @title Marketplace interface
/// @notice Interface for the Marketplace facet
/// @author HostIt Protocol
interface IMarketplace {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Mints a ticket for the specified buyer
    /// @param ticketId The ID of the ticket to mint
    /// @param feeType The type of fee to use for the ticket
    /// @param buyer The address of the buyer
    /// @return The token ID of the minted ticket
    function mintTicket(uint64 ticketId, FeeType feeType, address buyer) external payable returns (uint40);

    /// @notice Sets the fees for the specified ticket
    /// @param ticketId The ID of the ticket to set fees for
    /// @param feeTypes The types of fees to set
    /// @param fees The fees to set
    function setTicketFees(uint64 ticketId, FeeType[] calldata feeTypes, uint256[] calldata fees) external;

    /// @notice Claims a refund for the specified ticket
    /// @param ticketId The ID of the ticket to claim a refund for
    /// @param feeType The type of fee to claim a refund for
    /// @param tokenId The token ID of the ticket to claim a refund for
    /// @param to The address to send the refund to
    function claimRefund(uint64 ticketId, FeeType feeType, uint256 tokenId, address to) external;

    /// @notice Withdraws the ticket balance for the specified ticket
    /// @param ticketId The ID of the ticket to withdraw the balance for
    /// @param feeType The type of fee to withdraw the balance for
    /// @param to The address to send the balance to
    function withdrawTicketBalance(uint64 ticketId, FeeType feeType, address to) external;

    /// @notice Withdraws the HostIt balance for the specified fee type
    /// @param feeType The type of fee to withdraw the balance for
    /// @param to The address to send the balance to
    function withdrawHostItBalance(FeeType feeType, address to) external;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Checks if the specified fee type is enabled for the specified ticket
    /// @param ticketId The ID of the ticket to check
    /// @param feeType The type of fee to check
    /// @return True if the fee type is enabled, false otherwise
    function isFeeEnabled(uint64 ticketId, FeeType feeType) external view returns (bool);

    /// @notice Gets the address of the fee token for the specified fee type
    /// @param feeType The type of fee to get the address for
    /// @return The address of the fee token
    function getFeeTokenAddress(FeeType feeType) external view returns (address);

    /// @notice Gets the fee for the specified ticket and fee type
    /// @param ticketId The ID of the ticket to get the fee for
    /// @param feeType The type of fee to get
    /// @return The fee for the ticket and fee type
    function getTicketFee(uint64 ticketId, FeeType feeType) external view returns (uint256);

    /// @notice Gets the fees for the specified ticket
    /// @param ticketId The ID of the ticket to get the fees for
    /// @param feeType The type of fee to get
    /// @return ticketFee The ticket fee for the ticket
    /// @return hostItFee The HostIt fee for the ticket
    /// @return totalFee The total fee for the ticket
    function getAllFees(uint64 ticketId, FeeType feeType)
        external
        view
        returns (uint256 ticketFee, uint256 hostItFee, uint256 totalFee);

    /// @notice Gets the balance of the specified ticket for the specified fee type
    /// @param ticketId The ID of the ticket to get the balance for
    /// @param feeType The type of fee to get the balance for
    /// @return The balance of the ticket for the fee type
    function getTicketBalance(uint64 ticketId, FeeType feeType) external view returns (uint256);

    /// @notice Gets the balance of HostIt for the specified fee type
    /// @param feeType The type of fee to get the balance for
    /// @return The balance of HostIt for the fee type
    function getHostItBalance(FeeType feeType) external view returns (uint256);

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Calculates the HostIt fee for the specified fee
    /// @param fee The fee to calculate the HostIt fee for
    /// @return The HostIt fee for the fee
    function getHostItFee(uint256 fee) external pure returns (uint256);

    /// @notice Gets the refund period
    /// @return The refund period
    function getRefundPeriod() external pure returns (uint256);
}
