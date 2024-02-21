// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@oz/access/Ownable.sol";
import { ERC404Test } from "./ERC404.t.sol";
import { IERC404Legacy } from "src/legacy/IERC404Legacy.sol";
import { ERC404LegacyManagedURI } from "src/legacy/ERC404LegacyManagedURI.sol";

contract ERC404Test_mint is ERC404Test {
    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.deployer, 500e18);
    }

    function test_RevertsIf_NotAuthorized() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));
        erc404.mint(users.stranger, 1);
    }

    function testFuzz_RevertsIf_AmountIsTokenIdOrZero(uint128 amount) public {
        vm.assume(amount <= erc404.minted());

        vm.expectRevert(ERC404LegacyManagedURI.MustBeFractionalizedAmount.selector);
        erc404.mint(users.deployer, amount);
    }

    function testFuzz_RevertsIf_ExceedesTotalSupply(uint128 amount) public {
        vm.assume(amount > erc404.totalSupply() - erc404.currentSupply());

        vm.expectRevert(ERC404LegacyManagedURI.TotalSupplyExceeded.selector);
        erc404.mint(users.deployer, amount);
    }

    function test_MintsERC20() public {
        uint128 amount = 1e18;
        uint128 currentSupplyNow = erc404.currentSupply();
        uint256 balanceBefore = erc404.balanceOf(users.deployer);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ERC20Transfer(address(0), users.deployer, amount);

        erc404.mint(users.deployer, amount);

        assertEq(erc404.balanceOf(users.deployer), balanceBefore + amount);
        assertEq(erc404.currentSupply(), currentSupplyNow + amount);
    }

    function test_MintsERC721() public {
        uint128 amount = 1.5e18;
        uint256 nextTokenId = erc404.minted() + 1;

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.Transfer(address(0), users.deployer, nextTokenId);

        erc404.mint(users.deployer, amount);

        assertEq(erc404.ownerOf(nextTokenId), users.deployer);
        assertEq(erc404.minted(), nextTokenId);
    }

    function testFuzz_MintsERC721_InProportionToAmount(uint128 amount) public {
        vm.assume(amount > erc404.minted() && amount <= erc404.totalSupply() - erc404.currentSupply());
        uint256 nextTokenId = erc404.minted() + 1;
        uint256 tokenIdsToMint = amount / 1e18;

        for (uint256 i = 0; i < tokenIdsToMint; i++) {
            vm.expectEmit(address(erc404));
            emit IERC404Legacy.Transfer(address(0), users.deployer, nextTokenId + i);
        }

        erc404.mint(users.deployer, amount);

        for (uint256 i = 0; i < tokenIdsToMint; i++) {
            assertEq(erc404.ownerOf(nextTokenId + i), users.deployer);
        }
        assertEq(erc404.minted(), nextTokenId + tokenIdsToMint - 1);
    }
}
