// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

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

    /// @notice Mints a new token to a given address
    /// @param _to The address to receive the newly minted token
    /// @return tokenId_ The ID of the newly minted token
    function mint(address _to) external returns (uint256 tokenId_);

    /// @notice Pauses token transfers
    function pause() external;

    /// @notice Unpauses token transfers
    function unpause() external;

    /// @notice Returns the base URI of the NFT collection
    /// forge-lint: disable-next-line(mixed-case-function)
    function baseURI() external view returns (string memory);

    /// @notice Checks if token transfers are paused
    function paused() external view returns (bool);
}
