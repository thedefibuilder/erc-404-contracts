// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@oz/access/Ownable.sol";
import { ERC404LegacyFactory } from "src/legacy/ERC404LegacyFactory.sol";
import { ERC404LegacyFactoryTest } from "./ERC404LegacyFactory.t.sol";

contract ERC404LegacyFactory_setDeploymentFee is ERC404LegacyFactoryTest {
    function test_RevertsIf_NotOwner() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));
        factory.setDeploymentFee(0.1e18);
    }

    function test_ChangesDeploymentFee() public {
        uint128 newDeploymentFee = 0.2e18;

        vm.expectEmit(address(factory));
        emit ERC404LegacyFactory.DeploymentFeeChanged(factory.deploymentFee(), newDeploymentFee);

        vm.startPrank(users.admin);
        factory.setDeploymentFee(newDeploymentFee);

        assertEq(factory.deploymentFee(), newDeploymentFee);
        assertEq(factory.deploymentFeeForUser(users.stranger), newDeploymentFee);
    }
}
