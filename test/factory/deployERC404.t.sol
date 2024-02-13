// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { FactoryTest } from "test/factory/Factory.t.sol";
import { Factory } from "src/factory/Factory.sol";
import { ERC404ManagedURI } from "src/extensions/ERC404ManagedURI.sol";

contract Factory_deployERC404 is FactoryTest {
    function testFuzz_RevertsIf_DeploymentFeeNotEqual(uint128 deploymentFee) public {
        vm.assume(deploymentFee < factory.deploymentFee());

        vm.expectRevert(Factory.InsufficientDeploymentFee.selector);
        factory.deployERC404{ value: deploymentFee }("name", "symbol", "baseURI", 1);
    }

    function test_DuringFreePeriod_DeploymentIsFree() public {
        Factory.FreePeriod memory freePeriod =
            Factory.FreePeriod({ start: uint64(block.timestamp), end: uint64(block.timestamp + 1 days) });
        vm.startPrank(users.admin);
        factory.setFreePeriod(freePeriod);

        vm.expectEmit(true, false, false, false);
        emit Factory.ERC404Deployed(users.stranger, address(0));

        vm.startPrank(users.stranger);
        address erc404 = factory.deployERC404{ value: 0 }("name", "symbol", "baseURI", 1);

        assertEq(factory.deploymentsOf(users.stranger).length, 1);
        assertEq(factory.deploymentsOf(users.stranger)[0], erc404);
    }

    function test_DuringFreePeriod_NotFreeIfAlreadyDeployed() public {
        Factory.FreePeriod memory freePeriod =
            Factory.FreePeriod({ start: uint64(block.timestamp), end: uint64(block.timestamp + 1 days) });
        vm.startPrank(users.admin);
        factory.setFreePeriod(freePeriod);

        vm.startPrank(users.stranger);
        factory.deployERC404{ value: 0 }("name", "symbol", "baseURI", 1);

        vm.expectRevert(Factory.InsufficientDeploymentFee.selector);
        factory.deployERC404{ value: 0 }("name", "symbol", "baseURI", 1);
    }

    function test_IfSentMore_RefundsUser() public {
        vm.startPrank(users.deployer);
        uint256 vaultBalanceBefore = address(factory.vault()).balance;
        uint256 deployerBalanceBefore = address(users.deployer).balance;

        vm.expectEmit(true, false, false, false);
        emit Factory.ERC404Deployed(users.deployer, address(0));

        factory.deployERC404{ value: initialDeploymentFee + 1e10 }("name", "symbol", "baseURI", 1);

        assertEq(address(factory.vault()).balance, vaultBalanceBefore + initialDeploymentFee);
        assertEq(address(users.deployer).balance, deployerBalanceBefore - initialDeploymentFee);
    }

    function test_DeploysERC404() public {
        vm.startPrank(users.stranger);
        uint256 vaultBalanceBefore = address(factory.vault()).balance;

        vm.expectEmit(true, false, false, false);
        emit Factory.ERC404Deployed(users.stranger, address(0));

        address erc404 = factory.deployERC404{ value: initialDeploymentFee }("name", "symbol", "baseURI", 1);

        assertEq(factory.deploymentsOf(users.stranger).length, 1);
        assertEq(factory.deploymentsOf(users.stranger)[0], erc404);
        assertEq(address(factory.vault()).balance, vaultBalanceBefore + initialDeploymentFee);

        // Assert that ERC404ManagedURI was deployed
        address otherERC404 = address(new ERC404ManagedURI("name", "symbol", "baseURI", 1, users.stranger));
        assertEq(erc404.codehash, otherERC404.codehash);
    }
}
