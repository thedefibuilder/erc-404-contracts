// SPDX-License-Identifier: MIT
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC404 } from "./IERC404.sol";

abstract contract ERC404 is IERC404, Ownable {
    /// @inheritdoc IERC404
    string public name;

    /// @inheritdoc IERC404
    string public symbol;

    /// @inheritdoc IERC404
    uint8 public immutable decimals;

    /// @inheritdoc IERC404
    uint256 public immutable totalSupply;

    /// @inheritdoc IERC404
    uint256 public minted;

    /// @inheritdoc IERC404
    mapping(address user => uint256 balance) public balanceOf;

    /// @inheritdoc IERC404
    mapping(address owner => mapping(address operator => uint256 amount)) public allowance;

    /// @inheritdoc IERC404
    mapping(uint256 tokenId => address operator) public getApproved;

    /// @inheritdoc IERC404
    mapping(address owner => mapping(address operator => bool isApproved)) public isApprovedForAll;

    /// @dev Addresses whitelisted from minting / burning for gas savings (pairs, routers, etc)
    mapping(address user => bool isWhitelisted) public whitelist;

    // ---------------------- Internal state ---------------------- //
    /// @dev Owner of id in native representation
    mapping(uint256 tokenId => address owner) internal _ownerOf;

    /// @dev Array of owned ids in native representation
    mapping(address owner => uint256[] tokenIds) internal _owned;

    /// @dev Tracks indices for the _owned mapping
    mapping(uint256 tokenId => uint256 index) internal _ownedIndex;

    // Constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalNativeSupply_,
        address owner_
    )
        Ownable(owner_)
    {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = totalNativeSupply_ * (10 ** decimals);
    }

    /// @notice Initialization function to set pairs / etc
    ///         saving gas by avoiding mint / burn on unnecessary targets
    function setWhitelist(address target, bool state) public onlyOwner {
        whitelist[target] = state;
    }

    /// @inheritdoc IERC404
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];

        if (owner == address(0)) {
            revert NotFound();
        }
    }

    /// @inheritdoc IERC404
    /// @dev tokenURI must be implemented by child contract
    function tokenURI(uint256 id) public view virtual returns (string memory);

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
            if (from != _ownerOf[amountOrId]) {
                revert InvalidSender();
            }

            if (to == address(0)) {
                revert InvalidRecipient();
            }

            if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[amountOrId]) {
                revert Unauthorized();
            }

            balanceOf[from] -= _getUnit();

            unchecked {
                balanceOf[to] += _getUnit();
            }

            _ownerOf[amountOrId] = to;
            delete getApproved[amountOrId];

            // update _owned for sender
            uint256 updatedId = _owned[from][_owned[from].length - 1];
            _owned[from][_ownedIndex[amountOrId]] = updatedId;
            // pop
            _owned[from].pop();
            // update index for the moved id
            _ownedIndex[updatedId] = _ownedIndex[amountOrId];
            // push token to to owned
            _owned[to].push(amountOrId);
            // update index for to owned
            _ownedIndex[amountOrId] = _owned[to].length - 1;

            emit Transfer(from, to, amountOrId);
            emit ERC20Transfer(from, to, _getUnit());
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

    // ---------------------- Internal functions ---------------------- //
    /// @notice Internal function for fractional transfers
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 unit = _getUnit();
        uint256 balanceBeforeSender = balanceOf[from];
        uint256 balanceBeforeReceiver = balanceOf[to];

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        // Skip burn for certain addresses to save gas
        if (!whitelist[from]) {
            uint256 tokensToBurn = (balanceBeforeSender / unit) - (balanceOf[from] / unit);
            for (uint256 i = 0; i < tokensToBurn; i++) {
                _burn(from);
            }
        }

        // Skip minting for certain addresses to save gas
        if (!whitelist[to]) {
            uint256 tokensToMint = (balanceOf[to] / unit) - (balanceBeforeReceiver / unit);
            for (uint256 i = 0; i < tokensToMint; i++) {
                _mint(to);
            }
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    // Internal utility logic
    function _getUnit() internal view returns (uint256) {
        return 10 ** decimals;
    }

    function _mint(address to) internal virtual {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        unchecked {
            minted++;
        }

        uint256 id = minted;

        if (_ownerOf[id] != address(0)) {
            revert AlreadyExists();
        }

        _ownerOf[id] = to;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        emit Transfer(address(0), to, id);
    }

    function _burn(address from) internal virtual {
        if (from == address(0)) {
            revert InvalidSender();
        }

        uint256 id = _owned[from][_owned[from].length - 1];
        _owned[from].pop();
        delete _ownedIndex[id];
        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(from, address(0), id);
    }
}
