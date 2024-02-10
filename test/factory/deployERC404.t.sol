// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { FactoryTest } from "test/factory/Factory.t.sol";
import { IFactory } from "src/factory/IFactory.sol";

contract Factory_deployERC404 is FactoryTest {
    event ERC404Deployed(address indexed deployer, address indexed erc404);

    function testFuzz_RevertsWhen_DeploymentFeeNotEqual(uint256 deploymentFee) public {
        vm.assume(deploymentFee != factory.deploymentFee());

        vm.expectRevert(IFactory.InsufficientDeploymentFee.selector);
        factory.deployERC404("name", "symbol", 1);
    }

    function test_DeploysERC404() public {
        vm.startPrank(users.stranger);
        uint256 vaultBalanceBefore = address(factory.vault()).balance;

        vm.expectEmit(true, false, false, false);
        emit ERC404Deployed(users.stranger, address(0));

        address erc404 = factory.deployERC404{ value: initialDeploymentFee }("name", "symbol", 1);

        assertEq(factory.deploymentsOf(users.stranger).length, 1);
        assertEq(factory.deploymentsOf(users.stranger)[0], erc404);
        assertEq(address(factory.vault()).balance, vaultBalanceBefore + initialDeploymentFee);
    }
}
