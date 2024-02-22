// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC404 } from "@ERC404/interfaces/IERC404.sol";
import { ERC404ManagedURITest } from "./ERC404ManagedURI.t.sol";

contract ERC404ManagedURI_tokenURI is ERC404ManagedURITest {
    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.admin, 1000e18);
    }

    function testFuzz_RevertsIf_NotMinted(uint256 tokenId) public {
        vm.assume(tokenId == 0 || tokenId > erc404.minted());
        vm.expectRevert(IERC404.NotFound.selector);
        erc404.tokenURI(tokenId);
    }
}
