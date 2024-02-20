// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC404Legacy, IERC404Legacy } from "src/legacy/ERC404Legacy.sol";

contract ERC404LegacyManagedURI is Ownable, ERC404Legacy {
    using Strings for uint256;

    error MustBeFractionalizedAmount();
    error TotalSupplyExceeded();

    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    bytes4 private constant ERC4906_INTERFACE_ID = bytes4(0x49064906);
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 totalNFTSupply,
        address initialOwner
    )
        ERC404Legacy(name_, symbol_, 18, totalNFTSupply)
        Ownable(initialOwner)
    {
        baseURI = baseURI_;
    }

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

    function owner() public view override(IERC404Legacy, Ownable) returns (address) {
        return super.owner();
    }

    /// @notice Sets metadata information for the whole collection.
    /// @param uri The base URI for the token.
    function setBaseURI(string memory uri) public onlyOwner {
        if (bytes(baseURI).length > 0) {
            emit BatchMetadataUpdate(1, minted);
        }

        baseURI = uri;
    }

    /// @inheritdoc IERC404Legacy
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory base = baseURI;

        if (bytes(base).length > 0) {
            // This is necessary because tokenId can exceed the totalNFTSupply
            uint256 seed = uint256(keccak256(abi.encodePacked(tokenId)));
            uint256 artifactId = seed % (totalSupply / _UNIT) + 1;

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
