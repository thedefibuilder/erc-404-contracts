// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC404, IERC404 } from "src/ERC404.sol";

contract ERC404ManagedURI is Ownable, ERC404 {
    using Strings for uint256;

    error ZeroArtifacts();
    error ArtifactsGreaterThanTotalSupply();
    error MustBeFractionalizedAmount();
    error TotalSupplyExceeded();

    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    bytes4 private constant ERC4906_INTERFACE_ID = bytes4(0x49064906);
    uint256 private _totalArtifacts;
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

    function mint(address to, uint128 erc20Amount) external onlyOwner {
        if (erc20Amount <= minted) revert MustBeFractionalizedAmount();
        if (erc20Amount > totalSupply - currentSupply) revert TotalSupplyExceeded();

        uint256 balanceBeforeReceiver = balanceOf[to];
        uint256 balanceReceiverNow;
        unchecked {
            balanceReceiverNow = balanceBeforeReceiver + erc20Amount;
            currentSupply = currentSupply + erc20Amount;
        }
        balanceOf[to] = balanceReceiverNow;
        uint256 tokensToMint = (balanceReceiverNow / _UNIT) - (balanceBeforeReceiver / _UNIT);
        for (uint256 i = 0; i < tokensToMint; i++) {
            _mint(to);
        }

        emit ERC20Transfer(address(0), to, erc20Amount);
    }

    function owner() public view override(IERC404, Ownable) returns (address) {
        return super.owner();
    }

    /// @notice Sets metadata information for the whole collection.
    /// @param uri The base URI for the token.
    /// @param totalArtifacts The total number of items that were inserted in metadata folder.
    function setBaseURI(string memory uri, uint256 totalArtifacts) public onlyOwner {
        if (totalArtifacts == 0) revert ZeroArtifacts();
        if (totalArtifacts > totalSupply / _UNIT) revert ArtifactsGreaterThanTotalSupply();

        if (bytes(baseURI).length > 0) {
            emit BatchMetadataUpdate(0, minted);
        }

        baseURI = uri;
        _totalArtifacts = totalArtifacts;
    }

    /// @inheritdoc IERC404
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory base = baseURI;

        if (bytes(base).length > 0) {
            // This is necessary because tokenId can exceed the totalNFTSupply
            uint256 seed = uint256(keccak256(abi.encodePacked(tokenId)));
            uint256 artifactId = seed % (_totalArtifacts);

            return string.concat(base, artifactId.toString());
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
