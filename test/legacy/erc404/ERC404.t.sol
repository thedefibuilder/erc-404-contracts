// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { BaseTest } from "test/Base.t.sol";
import { ERC404LegacyManagedURI } from "src/legacy/ERC404LegacyManagedURI.sol";

contract ERC404Test is BaseTest {
    ERC404LegacyManagedURI public erc404;

    string public constant NAME = "name";
    string public constant SYMBOL = "symbol";
    string public constant BASE_URI = "https://example.com/";
    uint256 public constant TOTAL_NFT_SUPPLY = 10_000;

    function setUp() public virtual override {
        super.setUp();

        erc404 = new ERC404LegacyManagedURI("name", "symbol", BASE_URI, TOTAL_NFT_SUPPLY, users.deployer);
    }
}
