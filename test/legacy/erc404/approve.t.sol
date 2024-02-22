// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC404LegacyTest } from "./ERC404.t.sol";
import { IERC404Legacy } from "src/legacy/IERC404Legacy.sol";

contract ERC404_approve is ERC404LegacyTest {
    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.deployer, uint128(erc404.totalSupply()));
    }

    function testFuzz_WhenERC721_RevertsIf_NotAuthorized(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted() && tokenId != 0);
        vm.startPrank(users.stranger);

        vm.expectRevert(IERC404Legacy.Unauthorized.selector);
        erc404.approve(users.stranger, tokenId);
    }

    function testFuzz_WhenERC721_WhenSenderIsApprovedForAll_GetsApproved(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted() && tokenId != 0);
        vm.startPrank(users.deployer);
        erc404.setApprovalForAll(users.stranger, true);

        vm.expectEmit();
        emit IERC404Legacy.Approval(users.deployer, users.stranger, tokenId);

        vm.startPrank(users.stranger);
        erc404.approve(users.stranger, tokenId);
        assertEq(erc404.getApproved(tokenId), users.stranger);
    }

    function testFuzz_WhenERC721_WhenSenderIsOwner_GetsApproved(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted() && tokenId != 0);
        vm.startPrank(users.deployer);

        vm.expectEmit();
        emit IERC404Legacy.Approval(users.deployer, users.stranger, tokenId);

        erc404.approve(users.stranger, tokenId);
        assertEq(erc404.getApproved(tokenId), users.stranger);
    }

    function testFuzz_WhenERC20_SetsAllowance(uint256 amount) public {
        vm.assume(amount > erc404.minted() || amount == 0);
        vm.startPrank(users.deployer);

        vm.expectEmit();
        emit IERC404Legacy.Approval(users.deployer, users.stranger, amount);

        assertTrue(erc404.approve(users.stranger, amount));
        assertEq(erc404.allowance(users.deployer, users.stranger), amount);
    }
}
