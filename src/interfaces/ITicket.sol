// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ITicket is IERC721Metadata, IERC721Enumerable {
    /// @notice Emitted when the base URI is updated
    /// @param newBaseUri The new base URI set for the NFT collection
    event BaseURIUpdated(string indexed newBaseUri);

    /// @notice Emitted when the metadata of the NFT collection is updated
    /// @param newName The new name of the NFT collection
    event NameUpdated(string indexed newName);

    /// @notice Emitted when the metadata of the NFT collection is updated
    /// @param newSymbol The new symbol of the NFT collection
    event SymbolUpdated(string indexed newSymbol);

    /// @notice Emitted when a ticket is used
    /// @param tokenId The ID of the token that was used
    event TicketUsed(uint256 indexed tokenId);

    /// @dev The name of the NFT collection cannot be empty
    error NameCannotBeEmpty();

    /// @dev The ticket has already been used
    error TicketAlreadyUsed();

    /// @notice Initializes the contract
    /// @param owner The owner of the contract
    /// @param name The name of the NFT collection
    /// @param symbol The symbol of the NFT collection
    /// @param uri The URI of the NFT collection
    function initialize(address owner, string calldata name, string calldata symbol, string calldata uri) external;

    /// @notice Updates the name of the NFT collection
    /// @param _name The name to assign
    function updateName(string calldata _name) external;

    /// @notice Updates the symbol of the NFT collection
    /// @param _symbol The symbol to assign
    function updateSymbol(string calldata _symbol) external;

    /// @notice Updates the base URI of the NFT collection
    /// forge-lint: disable-next-line(mixed-case-function)
    function updateURI(string calldata _uri) external;

    /// @notice Uses a ticket, marking it as used and preventing future use
    /// @param _tokenId The ID of the token to use
    function useTicket(uint256 _tokenId) external;

    /// @notice Refunds a ticket
    /// @param _to The address to send refunded ticket
    /// @param _tokenId The ID of the ticket to refund
    function refundTicket(address _to, uint256 _tokenId) external;

    /// @notice Mints a new token to a given address
    /// @param _to The address to receive the newly minted token
    /// @return tokenId_ The ID of the newly minted token
    function mint(address _to) external returns (uint256 tokenId_);

    /// @notice Returns the base URI of the NFT collection
    /// forge-lint: disable-next-line(mixed-case-function)
    function baseURI() external view returns (string memory);

    /// @notice Checks if a ticket has been used
    /// @param _tokenId The ID of the token to check
    /// @return True if the ticket has been used, false otherwise
    function isUsed(uint256 _tokenId) external view returns (bool);
}
