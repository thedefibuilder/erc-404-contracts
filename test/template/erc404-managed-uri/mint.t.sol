// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@oz/access/Ownable.sol";
import { ERC20Events } from "@ERC404/lib/ERC20Events.sol";
import { ERC721Events } from "@ERC404/lib/ERC721Events.sol";
import { ERC404ManagedURI } from "src/templates/ERC404ManagedURI.sol";
import { ERC404ManagedURITest } from "./ERC404ManagedURI.t.sol";

contract ERC404ManagedURI_mint is ERC404ManagedURITest {
    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.admin, 1000e18);
    }

    function test_RevertsIf_Unauthorized() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));

        erc404.mint(users.stranger, 1e18);
    }

    function testFuzz_RevertsIf_MaxSupplyExceeded(uint256 mintAmount) public {
        vm.assume(mintAmount > erc404.maxSupply() - erc404.totalSupply());

        vm.expectRevert(ERC404ManagedURI.MaxSupplyExceeded.selector);

        erc404.mint(users.admin, mintAmount);
    }

    function test_Mints() public {
        uint256 minted = erc404.minted();
        vm.startPrank(users.deployer);

        vm.expectEmit(address(erc404));
        emit ERC20Events.Transfer(address(0), users.admin, 1e18);

        erc404.mint(users.admin, 1e18);

        assertEq(erc404.minted(), minted + 1);
    }
}
