// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { toTemplate, TemplateType, Template } from "src/types/Template.sol";
import { BaseTest } from "test/Base.t.sol";

contract TemplateTypes is BaseTest {
    function testFuzz_toTemplate(address implementation, uint8 templateType, uint88 deploymentFee) public {
        vm.assume(templateType < 2);
        bytes32 expected = bytes32(
            uint256(uint160(implementation)) << 96 | uint256(uint8(templateType)) << 88 | uint256(deploymentFee)
        );

        assertEq(Template.unwrap(toTemplate(implementation, TemplateType(templateType), deploymentFee)), expected);
    }

    function testFuzz_unwrap(address implementation, uint8 templateType, uint88 deploymentFee) public {
        vm.assume(templateType < 2);

        Template template = toTemplate(implementation, TemplateType(templateType), deploymentFee);

        (address unwrappedImplementation, TemplateType unwrappedTemplateType, uint88 unwrappedDeploymentFee) =
            template.unwrap();

        assertEq(unwrappedImplementation, template.implementation());
        assertEq(uint8(unwrappedTemplateType), uint8(template.templateType()));
        assertEq(unwrappedDeploymentFee, template.deploymentFee());
    }
}
