// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { stdError } from "forge-std/src/StdError.sol";
import { ERC404Test } from "./ERC404.t.sol";
import { IERC404Legacy } from "src/legacy/IERC404Legacy.sol";

contract ERC404Test_transferFrom is ERC404Test {
    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.deployer, 500e18);
    }

    function testFuzz_WhenERC721_RevertsIf_TokenIdIsNotOwnedBySender(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted());
        vm.expectRevert(IERC404Legacy.InvalidSender.selector);
        erc404.transferFrom(users.stranger, users.deployer, tokenId);
    }

    function testFuzz_WhenERC721_RevertsIf_RecipientIsZeroAddress(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted() && tokenId > 0);
        vm.expectRevert(IERC404Legacy.InvalidRecipient.selector);
        erc404.transferFrom(users.deployer, address(0), tokenId);
    }

    function testFuzz_WhenERC721_RevertsIf_NotAuthorized(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted() && tokenId > 0);
        vm.startPrank(users.stranger);

        vm.expectRevert(IERC404Legacy.Unauthorized.selector);
        erc404.transferFrom(users.deployer, users.stranger, tokenId);
    }

    function test_WhenERC721_WhenApprovedForAll_TransfersBoth() public {
        uint256 tokenId = 1;
        uint256 balanceSenderBefore = erc404.balanceOf(users.deployer);
        erc404.setApprovalForAll(users.stranger, true);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.Transfer(users.deployer, users.stranger, tokenId);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ERC20Transfer(users.deployer, users.stranger, 1e18);

        vm.startPrank(users.stranger);
        erc404.transferFrom(users.deployer, users.stranger, tokenId);

        assertEq(erc404.balanceOf(users.deployer), balanceSenderBefore - 1e18);
        assertEq(erc404.balanceOf(users.stranger), 1e18);
        assertEq(erc404.ownerOf(tokenId), users.stranger);
    }

    function test_WhenERC721_WhenApproved_TransfersBoth() public {
        uint256 tokenId = 1;
        uint256 balanceSenderBefore = erc404.balanceOf(users.deployer);
        erc404.approve(users.stranger, tokenId);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.Transfer(users.deployer, users.stranger, tokenId);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ERC20Transfer(users.deployer, users.stranger, 1e18);

        vm.startPrank(users.stranger);
        erc404.transferFrom(users.deployer, users.stranger, tokenId);

        assertEq(erc404.balanceOf(users.deployer), balanceSenderBefore - 1e18);
        assertEq(erc404.balanceOf(users.stranger), 1e18);
        assertEq(erc404.ownerOf(tokenId), users.stranger);
        assertEq(erc404.getApproved(tokenId), address(0));
    }

    function testFuzz_WhenERC721_WhenOwner_TransfersBoth(uint256 tokenId) public {
        vm.assume(tokenId <= erc404.minted() && tokenId > 0);
        uint256 balanceSenderBefore = erc404.balanceOf(users.deployer);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.Transfer(users.deployer, users.stranger, tokenId);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ERC20Transfer(users.deployer, users.stranger, 1e18);

        erc404.transferFrom(users.deployer, users.stranger, tokenId);

        assertEq(erc404.balanceOf(users.deployer), balanceSenderBefore - 1e18);
        assertEq(erc404.balanceOf(users.stranger), 1e18);
        assertEq(erc404.ownerOf(tokenId), users.stranger);
    }

    function testFuzz_WhenERC20_RevertsIf_NotAllowed(uint256 amount) public {
        uint256 balance = erc404.balanceOf(users.deployer);
        vm.assume(amount > erc404.minted() && amount <= balance);
        vm.startPrank(users.stranger);

        vm.expectRevert(stdError.arithmeticError);
        erc404.transferFrom(users.deployer, users.stranger, amount);
    }

    function testFuzz_WhenERC20_CallerIsAllowed_TransfersBoth(uint256 amount) public {
        uint256 balanceSenderBefore = erc404.balanceOf(users.deployer);
        vm.assume(amount > erc404.minted() && amount <= balanceSenderBefore);
        erc404.approve(users.stranger, amount);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ERC20Transfer(users.deployer, users.stranger, amount);

        vm.startPrank(users.stranger);
        erc404.transferFrom(users.deployer, users.stranger, amount);

        assertEq(erc404.balanceOf(users.deployer), balanceSenderBefore - amount);
        assertEq(erc404.balanceOf(users.stranger), amount);
        assertEq(erc404.allowance(users.deployer, users.stranger), 0);
    }
}
