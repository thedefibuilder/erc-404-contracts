// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Factory } from "src/factory/Factory.sol";
import { FactoryTest } from "test/factory/Factory.t.sol";

contract Factory_setDeploymentFee is FactoryTest {
    function test_RevertsIf_NotOwner() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));
        factory.setDeploymentFee(0.1e18);
    }

    function test_ChangesDeploymentFee() public {
        uint128 newDeploymentFee = 0.2e18;

        vm.expectEmit(address(factory));
        emit Factory.DeploymentFeeChanged(factory.deploymentFee(), newDeploymentFee);

        vm.startPrank(users.admin);
        factory.setDeploymentFee(newDeploymentFee);

        assertEq(factory.deploymentFee(), newDeploymentFee);
        assertEq(factory.deploymentFeeForUser(users.stranger), newDeploymentFee);
    }
}
