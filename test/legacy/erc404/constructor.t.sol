// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC20 } from "@oz/interfaces/IERC20.sol";
import { IERC721 } from "@oz/interfaces/IERC721.sol";
import { IERC165 } from "@oz/interfaces/IERC165.sol";
import { ERC404LegacyTest } from "./ERC404.t.sol";

contract ERC404LegacyTest_constructor is ERC404LegacyTest {
    function test_constructor() public {
        assertEq(erc404.name(), NAME);
        assertEq(erc404.symbol(), SYMBOL);
        assertEq(erc404.decimals(), 18);
        assertEq(erc404.totalSupply(), TOTAL_NFT_SUPPLY * 10 ** 18);
        assertEq(erc404.owner(), users.deployer);
        assertNotEq(bytes(erc404.baseURI()).length, 0);

        assertTrue(erc404.supportsInterface(ERC4906_INTERFACE_ID));
        assertTrue(erc404.supportsInterface(type(IERC20).interfaceId));
        assertTrue(erc404.supportsInterface(type(IERC721).interfaceId));
        assertTrue(erc404.supportsInterface(type(IERC165).interfaceId));
    }
}
