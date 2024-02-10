// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC404, IERC404 } from "src/ERC404.sol";

contract ERC404ManagedURI is Ownable, ERC404 {
    using Strings for uint256;

    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    bytes4 private constant ERC4906_INTERFACE_ID = bytes4(0x49064906);
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalNFTSupply,
        address initialOwner
    )
        ERC404(name, symbol, 18, totalNFTSupply)
        Ownable(initialOwner)
    { }

    function owner() public view override(IERC404, Ownable) returns (address) {
        return super.owner();
    }

    function setBaseURI(string memory uri) public onlyOwner {
        if (bytes(baseURI).length > 0) {
            emit BatchMetadataUpdate(0, minted);
        }

        baseURI = uri;
    }

    /// @inheritdoc IERC404
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory base = baseURI;

        if (bytes(base).length > 0) {
            // This is necessary because tokenId can exceed the totalNFTSupply
            uint256 seed = uint256(keccak256(abi.encodePacked(tokenId)));
            uint256 uriId = seed % (totalSupply / _UNIT);

            return string.concat(base, uriId.toString());
        }

        return "";
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == ERC4906_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    function _isExempted(address) internal pure override returns (bool) {
        return false;
    }
}
