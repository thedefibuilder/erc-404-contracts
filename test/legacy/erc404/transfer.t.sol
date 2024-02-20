// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { stdError } from "forge-std/src/StdError.sol";
import { ERC404Test } from "./ERC404.t.sol";
import { IERC404Legacy } from "src/legacy/IERC404Legacy.sol";

contract ERC404Test_transfer is ERC404Test {
    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.deployer, 100e18);
    }

    function test_RevertsIf_IsufficientBalance() public {
        vm.expectRevert(stdError.arithmeticError);
        erc404.transfer(users.stranger, 101e18);
    }

    function testFuzz_ERC20BalancesAreUpdated(uint256 amount) public {
        uint256 balance = erc404.balanceOf(users.deployer);
        vm.assume(balance >= amount);
        uint256 strangerBalance = erc404.balanceOf(users.stranger);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ERC20Transfer(users.deployer, users.stranger, amount);

        erc404.transfer(users.stranger, amount);

        assertTrue(erc404.balanceOf(users.deployer) == balance - amount);
        assertTrue(erc404.balanceOf(users.stranger) == strangerBalance + amount);
    }

    function testFuzz_SenderERC721BalanceIsBurned(uint256 amount) public {
        uint256 balance = erc404.balanceOf(users.deployer);
        vm.assume(balance >= amount);
        uint256 lastTokenId = erc404.minted();
        uint256 nftsToBurn = amount / 1e18;

        for (uint256 i = 0; i < nftsToBurn; i++) {
            vm.expectEmit(address(erc404));
            emit IERC404Legacy.Transfer(users.deployer, address(0), lastTokenId - i);
        }

        erc404.transfer(users.stranger, amount);

        for (uint256 i = 0; i < nftsToBurn; i++) {
            assertTrue(erc404.ownerOf(lastTokenId - i) == address(0));
            assertTrue(erc404.getApproved(lastTokenId - 1) == address(0));
        }
    }

    function testFuzz_ReceiverERC721BalanceIsMinted(uint256 amount) public {
        vm.assume(amount >= 1e18 && amount < erc404.balanceOf(users.deployer));
        uint256 nextTokenId = erc404.minted() + 1;
        uint256 nftsToMint = amount / 1e18;

        for (uint256 i = 0; i < nftsToMint; i++) {
            vm.expectEmit(address(erc404));
            emit IERC404Legacy.Transfer(address(0), users.stranger, nextTokenId + i);
        }

        erc404.transfer(users.stranger, amount);

        for (uint256 i = 0; i < nftsToMint; i++) {
            assertTrue(erc404.ownerOf(nextTokenId + i) == users.stranger);
            assertTrue(erc404.getApproved(nextTokenId + i) == address(0));
        }
    }
}
