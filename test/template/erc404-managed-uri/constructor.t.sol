// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC404ManagedURITest } from "./ERC404ManagedURI.t.sol";

contract ERC404ManagedURI_constructor is ERC404ManagedURITest {
    function test_Constructor() public {
        assertEq(erc404.name(), NAME);
        assertEq(erc404.symbol(), SYMBOL);
        assertEq(erc404.baseURI(), BASE_URI);
        assertEq(erc404.maxSupply(), TOTAL_NFT_SUPPLY * 10 ** 18);
        assertEq(erc404.owner(), users.deployer);
        assertTrue(erc404.supportsInterface(ERC4906_INTERFACE_ID));
    }
}
