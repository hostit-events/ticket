// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ITicket is IERC721Enumerable {
    /// @notice Emitted when the base URI is updated
    /// @param newBaseUri The new base URI set for the NFT collection
    event BaseURIUpdated(string indexed newBaseUri);

    /// @notice Emitted when the metadata of the NFT collection is updated
    /// @param newName The new name of the NFT collection
    event NameUpdated(string indexed newName);

    /// @notice Emitted when the metadata of the NFT collection is updated
    /// @param newSymbol The new symbol of the NFT collection
    event SymbolUpdated(string indexed newSymbol);

    function initialize(address, string calldata, string calldata) external;

    /// @notice Updates the name of the NFT collection
    function updateName(string calldata) external;

    /// @notice Updates the symbol of the NFT collection
    function updateSymbol(string calldata) external;

    /// @notice Updates the base URI of the NFT collection
    /// forge-lint: disable-next-line(mixed-case-function)
    function updateURI(string calldata) external;

    /// @notice Mints a new token to a given address
    function mint(address) external returns (uint256);

    /// @notice Pauses token transfers
    function pause() external;

    /// @notice Unpauses token transfers
    function unpause() external;
}
