// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC165 } from "@oz/utils/introspection/IERC165.sol";

interface IERC404Legacy is IERC165 {
    // Events
    event ERC20Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ERC721Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();
    error Unauthorized();

    /// @notice Current mint counter, monotonically increasing to ensure accurate ownership.
    function minted() external view returns (uint128);

    /// @notice Current ERC20 supply counter in fractionalized amount.
    function currentSupply() external view returns (uint128);

    /// @notice Mandatory function to ensure compatibility with NFT marketplaces.
    function owner() external view returns (address);

    /// @dev Token name.
    /// @custom:base ERC-20, ERC-721
    function name() external view returns (string memory);

    /// @dev Token symbol.
    /// @custom:base ERC-20, ERC-721
    function symbol() external view returns (string memory);

    /// @dev Decimals for fractional representation.
    /// @custom:base ERC-20
    function decimals() external view returns (uint8);

    /// @dev Total supply in fractionalized representation.
    /// @custom:base ERC-20
    function totalSupply() external view returns (uint256);

    /// @dev Balance of user in fractional representation.
    /// @custom:base ERC-20
    function balanceOf(address user) external view returns (uint256);

    /// @dev Allowance of user in fractional representation.
    /// @custom:base ERC-20
    function allowance(address owner, address operator) external view returns (uint256);

    /// @dev Approval in native representaion.
    /// @custom:base ERC-721
    function getApproved(uint256 id) external view returns (address operator);

    /// @dev Approval for all in native representation.
    /// @custom:base ERC-721
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Function to find owner of a given native token.
    /// @custom:base ERC-721
    function ownerOf(uint256 id) external view returns (address owner);

    /// @notice Function to get token URI.
    /// @custom:base ERC-721
    function tokenURI(uint256 id) external view returns (string memory);

    /// @notice Function for token approvals.
    /// @dev This function assumes id / native if amount less than or equal to current max id.
    /// @custom:base ERC-721, ERC-20
    function approve(address spender, uint256 amountOrId) external returns (bool);

    /// @notice Function native approvals.
    /// @custom:base ERC-721
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Function for mixed transfers.
    /// @dev This function assumes id / native if amount less than or equal to current max id.
    /// @custom:base ERC-721, ERC-20
    function transferFrom(address from, address to, uint256 amountOrId) external;

    /// @notice Function for fractional transfers.
    /// @custom:base ERC-20
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Function for native transfers with contract support.
    /// @custom:base ERC-721
    function safeTransferFrom(address from, address to, uint256 id) external;

    /// @notice Function for native transfers with contract support and callback data.
    /// @custom:base ERC-721
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;
}
