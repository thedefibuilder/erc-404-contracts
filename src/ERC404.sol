// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC404 } from "./IERC404.sol";

abstract contract ERC404 is IERC404, ERC165 {
    /// @inheritdoc IERC404
    string public name;

    /// @inheritdoc IERC404
    string public symbol;

    /// @inheritdoc IERC404
    uint8 public immutable decimals;

    /// @inheritdoc IERC404
    uint256 public immutable totalSupply;

    /// @inheritdoc IERC404
    uint128 public minted;
    uint128 public currentSupply;

    /// @inheritdoc IERC404
    mapping(address user => uint256 balance) public balanceOf;

    /// @inheritdoc IERC404
    mapping(address owner => mapping(address operator => uint256 amount)) public allowance;

    /// @inheritdoc IERC404
    mapping(uint256 tokenId => address operator) public getApproved;

    /// @inheritdoc IERC404
    mapping(address owner => mapping(address operator => bool isApproved)) public isApprovedForAll;

    // ---------------------- Internals ---------------------- //
    /// @dev Representation of a single unit of the token.
    uint256 internal immutable _UNIT;

    /// @dev Owner of id in NFT representation.
    mapping(uint256 tokenId => address owner) internal _ownerOf;

    /// @dev Array of owned ids in NFT representation.
    mapping(address owner => uint256[] tokenIds) internal _owned;

    /// @dev Tracks indices for the _owned mapping.
    mapping(uint256 tokenId => uint256 index) internal _ownedIndex;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalNFTSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _UNIT = 10 ** decimals_;
        totalSupply = totalNFTSupply_ * _UNIT;
    }

    /// @inheritdoc IERC404
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        return _requireOwned(id);
    }

    /// @inheritdoc IERC404
    function approve(address spender, uint256 amountOrId) public virtual returns (bool) {
        if (amountOrId <= minted && amountOrId > 0) {
            address owner = _ownerOf[amountOrId];

            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert Unauthorized();
            }

            getApproved[amountOrId] = spender;

            emit Approval(owner, spender, amountOrId);
        } else {
            allowance[msg.sender][spender] = amountOrId;

            emit Approval(msg.sender, spender, amountOrId);
        }

        return true;
    }

    /// @inheritdoc IERC404
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC404
    function transferFrom(address from, address to, uint256 amountOrId) public virtual {
        if (amountOrId <= minted) {
            if (from != _ownerOf[amountOrId]) revert InvalidSender();
            if (to == address(0)) revert InvalidRecipient();
            if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[amountOrId]) {
                revert Unauthorized();
            }

            balanceOf[from] -= _UNIT;
            unchecked {
                balanceOf[to] += _UNIT;
            }

            _ownerOf[amountOrId] = to;
            delete getApproved[amountOrId];

            uint256 updatedId = _owned[from][_owned[from].length - 1];
            _owned[from][_ownedIndex[amountOrId]] = updatedId;
            _owned[from].pop();
            _ownedIndex[updatedId] = _ownedIndex[amountOrId];
            _owned[to].push(amountOrId);
            _ownedIndex[amountOrId] = _owned[to].length - 1;

            emit Transfer(from, to, amountOrId);
            emit ERC20Transfer(from, to, _UNIT);
        } else {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max) {
                allowance[from][msg.sender] = allowed - amountOrId;
            }

            _transfer(from, to, amountOrId);
        }
    }

    /// @inheritdoc IERC404
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @inheritdoc IERC404
    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0
                && IERC721Receiver(to).onERC721Received(msg.sender, from, id, "")
                    != IERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @inheritdoc IERC404
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0
                && IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                    != IERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC721).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC404
    function tokenURI(uint256 id) public view virtual returns (string memory);

    // ---------------------- Internal functions ---------------------- //
    /// @notice Internal function for fractional transfers.
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 balanceBeforeSender = balanceOf[from];
        uint256 balanceBeforeReceiver = balanceOf[to];

        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }

        // Skip burn for certain addresses (i.e. trading pairs) to save gas.
        if (!_isExempted(from)) {
            uint256 tokensToBurn = (balanceBeforeSender / _UNIT) - (balanceOf[from] / _UNIT);
            for (uint256 i = 0; i < tokensToBurn; i++) {
                _burn(from);
            }
        }

        // Skip minting for certain addresses (i.e. trading pairs) to save gas.
        if (!_isExempted(to)) {
            uint256 tokensToMint = (balanceOf[to] / _UNIT) - (balanceBeforeReceiver / _UNIT);
            for (uint256 i = 0; i < tokensToMint; i++) {
                _mint(to);
            }
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    function _mint(address to) internal virtual {
        if (to == address(0)) revert InvalidRecipient();

        unchecked {
            minted++;
        }
        uint256 id = minted;

        if (_ownerOf[id] != address(0)) revert AlreadyExists();

        _ownerOf[id] = to;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        emit Transfer(address(0), to, id);
    }

    function _burn(address from) internal virtual {
        if (from == address(0)) revert InvalidSender();

        uint256 id = _owned[from][_owned[from].length - 1];
        _owned[from].pop();
        delete _ownedIndex[id];
        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(from, address(0), id);
    }

    function _requireOwned(uint256 id) internal view returns (address owner) {
        owner = _ownerOf[id];

        if (_ownerOf[id] == address(0)) revert NotFound();
    }

    /// @notice Internal function to check if an address is exempted from NFT mint/burn on transfer.
    function _isExempted(address target) internal view virtual returns (bool);
}
