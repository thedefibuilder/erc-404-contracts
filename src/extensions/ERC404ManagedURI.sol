// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC404, IERC404 } from "src/ERC404.sol";

contract ERC404ManagedURI is Ownable, ERC404 {
    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    bytes4 private constant ERC4906_INTERFACE_ID = bytes4(0x49064906);

    uint256 public totalRegisteredURIs;
    mapping(uint256 uriId => string uri) private _tokenURIs;

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

    // TODO: Add batch tokenURI register support

    function registerTokenURI(string memory uri) public onlyOwner {
        _tokenURIs[totalRegisteredURIs] = uri;
        totalRegisteredURIs++;

        if (minted > totalRegisteredURIs) {
            emit BatchMetadataUpdate(0, minted);
        }
    }

    /// @inheritdoc IERC404
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        // TODO: Improve the URI selection
        uint256 uriId = uint256(keccak256(abi.encode(tokenId))) % totalRegisteredURIs;
        return _tokenURIs[uriId];
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == ERC4906_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    function _isExempted(address) internal pure override returns (bool) {
        return false;
    }
}
