// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721RoyaltyUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ITicket} from "@ticket/interfaces/ITicket.sol";

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      ╔╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╗
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⢹⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀      ╠╝                                                                   ╚╣
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⡟⠹⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀      ╠╡ ▲▲▲ ▲▲▲                  HOST IT TICKET                ▲▲▲ ▲▲▲    ╞╣
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⠟⢁⡈⠻⣿⣦⣨⣿⣿⣶⣤⣤⣴⣦⡀⠀⠀      ╠╡                                                                   ╞╣
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⠟⢁⣴⣿⣿⣦⡈⠻⣿⣯⡈⠻⢿⣿⣿⣿⣿⠆⠀      ╠╡ ► EVENT: ░▒▓█ NEON NIGHTS █▓▒░            ► SECTOR: ◢ Z-07 ◣      ╞╣
⠀⠀⠀⠀⠀⠀⢀⣴⣿⠟⢁⣴⣿⣿⣿⣿⣿⣿⣦⡈⠻⣿⣶⣿⠿⢿⠟⠁⠀⠀      ╠╡ ► DATE: █ 2106.07.02 █                    ► CREDIT: ◊ 150 ◊       ╞╣
⠀⠀⠀⠀⢀⣴⣿⠟⢁⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠆⢈⣿⣿⠆⠀⠀⠀⠀⠀      ╠╡ ► TIME: ⟦ 22:00 ⟧                          ► ACCESS: ■ PREMIUM ■   ╞╣
⠀⠀⢀⣴⣿⣟⠁⠰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢁⣴⣿⠟⠁⠀⠀⠀⠀⠀⠀      ╠╡                                                                   ╞╣
⠀⠰⣿⣿⣿⣿⣷⣦⡈⠻⣿⣿⣿⣿⣿⣿⠟⢁⣴⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀      ╠╡ ░░▒▒▓▓██ ░░▒▒▓▓██ ░░▒▒▓▓██ ░░▒▒▓▓██ ░░▒▒▓▓██ ░░▒▒▓▓██ ░░▒▒▓▓██    ╞╣
⠀⠀⠈⠻⠟⠛⠛⠿⣿⣦⡈⠻⣿⣿⠟⢁⣴⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      ╠╡                                                                   ╞╣
⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣆⠈⢁⣴⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      ╠╡ ◤ ADMITS ONE ◥                              ◄ SCAN TO ENTER ►     ╞╣
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣷⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      ╠╗                                                                   ╔╣
⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      ╠╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╣
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      ╚╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╝
*/

/// @title Ticket
/// @notice ERC721 Ticket Implementation
/// @author HostIt Protocol
contract Ticket is
    ERC721EnumerableUpgradeable,
    ERC721RoyaltyUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ITicket
{
    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721URI")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC721_URI_LOCATION = 0x9faa092706460340520342296a39ef71008484de7dbcf27f804dae6b9b4ddd00;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC721_LOCATION = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC721URI
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct ERC721URIStorage {
        string _uri;
    }

    /// @dev Internal function to retrieve the storage location of the ERC721URIStorage struct
    function _getErc721UriStorage() private pure returns (ERC721URIStorage storage $) {
        assembly {
            $.slot := ERC721_URI_LOCATION
        }
    }

    /// @dev Internal function to retrieve the storage location of the ERC721Storage struct
    function _getErc721Storage() private pure returns (ERC721Storage storage $) {
        assembly {
            $.slot := ERC721_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Constructor disables initializers on implementation contracts
    /// @dev Only proxy contracts can initialize this contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _owner The owner of the contract
    /// @param _name The name of the NFT collection
    /// @param _uri The URI of the NFT collection
    function initialize(address _owner, string calldata _name, string calldata _symbol, string calldata _uri)
        public
        initializer
    {
        string memory symbol = bytes(_symbol).length != 0 ? _symbol : "TICKET";
        __ERC721_init(_name, symbol);
        __ERC721Enumerable_init();
        __ERC721Royalty_init();
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();

        // Set default royalty to 5%
        _setDefaultRoyalty(_owner, 500);

        _getErc721UriStorage()._uri = _uri;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Allows the owner to update the name of the NFT collection
    /// @param _name The name to assign
    function updateName(string calldata _name) external onlyOwner {
        _getErc721Storage()._name = _name;
        emit NameUpdated(_name);
    }

    /// @notice Allows the owner to update the symbol of the NFT collection
    /// @param _symbol The symbol to assign
    function updateSymbol(string calldata _symbol) external onlyOwner {
        _getErc721Storage()._symbol = _symbol;
        emit SymbolUpdated(_symbol);
    }

    /// @notice Allows the owner to set the base URI
    /// @param __baseUri The URI to assign
    /// forge-lint: disable-next-line(mixed-case-function)
    function updateURI(string calldata __baseUri) external onlyOwner {
        _getErc721UriStorage()._uri = __baseUri;
        emit BaseURIUpdated(__baseUri);
    }

    /// @notice Mints a new token to a given address
    /// @param _to The address to receive the newly minted token
    /// @return tokenId_ The ID of the newly minted token
    function mint(address _to) external onlyOwner returns (uint256 tokenId_) {
        // Increment tokenId based on total supply
        tokenId_ = totalSupply() + 1;
        _safeMint(_to, tokenId_);
    }

    /// @notice Pauses token transfers
    /// @dev This function is used to pause token transfers apart from minting
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses token transfers
    /// @dev This function is used to unpause token transfers apart from minting
    function unpause() external onlyOwner {
        _unpause();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              TICKET OVERRIDES
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Transfers the token from one address to another
    /// @param from The address to transfer the token from
    /// @param to The address to transfer the token to
    /// @param tokenId The ID of the token to transfer
    /// forge-lint: disable-next-item(erc20-unchecked-transfer)
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(IERC721, ERC721Upgradeable)
        whenNotPaused
    {
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Transfers the token from one address to another
    /// @param from The address to transfer the token from
    /// @param to The address to transfer the token to
    /// @param tokenId The ID of the token to transfer
    /// @param data Data to send with the transfer
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721Upgradeable)
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function paused() public view override(ITicket, PausableUpgradeable) returns (bool) {
        return PausableUpgradeable.paused();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Returns the metadata URI for the TicketNFT
    /// @dev This function returns the base URI set for the NFT collection, which is used
    /// @param _tokenId The ID of the token
    /// @return The URI pointing to the token's metadata
    /// forge-lint: disable-next-line(mixed-case-function)
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, IERC721Metadata)
        returns (string memory)
    {
        _requireOwned(_tokenId);
        return _baseURI();
    }

    /// @notice Returns the metadata URI for the TicketNFT
    /// @dev This function returns the base URI set for the NFT collection, which is used
    /// @return The URI pointing to the collection's metadata
    /// forge-lint: disable-next-line(mixed-case-function)
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /// @notice Returns whether a given interface is supported by the contract
    /// @param _interfaceId The interface ID to check
    /// @return Whether the interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(IERC165, ERC721RoyaltyUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Internal override for base URI, returns the set base URI
    /// @notice This function is used to retrieve the base URI for the NFT collection
    /// @return The base URI for the NFT collection
    /// forge-lint: disable-next-line(mixed-case-function)
    function _baseURI() internal view override returns (string memory) {
        return _getErc721UriStorage()._uri;
    }

    /// @dev Internal override for token transfer logic
    /// @param _to The address to transfer the token to
    /// @param _tokenId The ID of the token to transfer
    /// @param _auth The address authorized to transfer the token
    /// @return The address of the token owner
    function _update(address _to, uint256 _tokenId, address _auth)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        return ERC721EnumerableUpgradeable._update(_to, _tokenId, _auth);
    }

    /// @dev Internal override for increasing balance
    /// @param account The address to increase the balance for
    /// @param amount The amount to increase the balance by
    function _increaseBalance(address account, uint128 amount)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        ERC721EnumerableUpgradeable._increaseBalance(account, amount);
    }

    /// @dev Internal override for upgrade logic
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
