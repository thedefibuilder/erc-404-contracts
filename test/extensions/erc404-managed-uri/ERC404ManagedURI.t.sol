// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { BaseTest } from "test/Base.t.sol";
import { ERC404ManagedURI } from "src/extensions/ERC404ManagedURI.sol";

contract ERC404ManagedURITest is BaseTest {
    ERC404ManagedURI public erc404;

    string public constant NAME = "name";
    string public constant SYMBOL = "symbol";
    uint256 public constant TOTAL_NFT_SUPPLY = 10_000;

    function setUp() public override {
        super.setUp();

        erc404 = new ERC404ManagedURI("name", "symbol", TOTAL_NFT_SUPPLY, users.deployer);
    }
}
