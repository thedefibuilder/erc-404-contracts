// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@oz/access/Ownable.sol";
import { Strings } from "@oz/utils/Strings.sol";
import { ERC404 } from "@ERC404/ERC404.sol";

contract ERC404ManagedURI is ERC404, Ownable {
    using Strings for uint256;

    error MustBeFractionalizedAmount();
    error MaxSupplyExceeded();

    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    bytes4 private constant ERC4906_INTERFACE_ID = bytes4(0x49064906);
    uint256 maxSupply;
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 totalNFTSupply,
        address initialOwner
    )
        ERC404(name_, symbol_, 18)
        Ownable(initialOwner)
    {
        maxSupply = totalNFTSupply * units;
        baseURI = baseURI_;
    }

    function mint(address to, uint128 erc20Amount) external onlyOwner {
        if (erc20Amount <= minted) revert MustBeFractionalizedAmount();
        if (erc20Amount > maxSupply - totalSupply) revert MaxSupplyExceeded();

        _mintERC20(to, erc20Amount);
    }

    /// @notice Sets metadata information for the whole collection.
    /// @param uri The base URI for the token.
    function setBaseURI(string memory uri) public onlyOwner {
        if (bytes(baseURI).length > 0) {
            emit BatchMetadataUpdate(1, minted);
        }
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 0 || tokenId > minted) revert NotFound();

        string memory base = baseURI;
        if (bytes(base).length > 0) {
            return string.concat(base, tokenId.toString());
        }
        return "";
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == ERC4906_INTERFACE_ID || super.supportsInterface(interfaceId);
    }
}
