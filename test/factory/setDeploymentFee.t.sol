// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FactoryTest } from "test/factory/Factory.t.sol";

contract Factory_setDeploymentFee is FactoryTest {
    event DeploymentFeeChanged(uint256 oldDeploymentFee, uint256 newDeploymentFee);

    function test_RevertsWhen_NotOwner() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));
        factory.setDeploymentFee(0.1e18);
    }

    function test_ChangesOwner() public {
        uint256 newDeploymentFee = 0.2e18;

        vm.expectEmit(address(factory));
        emit DeploymentFeeChanged(factory.deploymentFee(), newDeploymentFee);

        vm.startPrank(users.admin);
        factory.setDeploymentFee(newDeploymentFee);

        assertEq(factory.deploymentFee(), newDeploymentFee);
    }
}
