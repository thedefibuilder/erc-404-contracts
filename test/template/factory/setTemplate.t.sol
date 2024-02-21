// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@oz/access/Ownable.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_setTemplate is TemplateFactoryTest {
    bytes32 public templateId = bytes32(uint256(1));
    TemplateFactory.Template public removalTemplate = TemplateFactory.Template({
        implementation: address(0),
        templateType: TemplateFactory.TemplateType.SimpleContract,
        deploymentFee: 0
    });
    TemplateFactory.Template public template = TemplateFactory.Template({
        implementation: address(1),
        templateType: TemplateFactory.TemplateType.SimpleContract,
        deploymentFee: 0
    });

    function test_RevertsIf_Unauthorized() public {
        vm.startPrank(users.stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));

        factory.setTemplate(templateId, template);
    }

    function test_AddsTemplate() public {
        vm.startPrank(users.admin);

        vm.expectEmit(address(factory));
        emit TemplateFactory.TemplateSet(
            templateId, template.implementation, template.templateType, template.deploymentFee
        );

        factory.setTemplate(templateId, template);

        assertEq(factory.getTemplate(templateId).deploymentFee, template.deploymentFee);
        assertEq(factory.getTemplate(templateId).implementation, template.implementation);
        assertTrue(factory.getTemplate(templateId).templateType == template.templateType);
        assertContains(factory.templateIds(), templateId);
    }

    function test_RemovesTemplate() public {
        vm.startPrank(users.admin);
        factory.setTemplate(templateId, template);

        vm.expectEmit(address(factory));
        emit TemplateFactory.TemplateSet(
            templateId, removalTemplate.implementation, removalTemplate.templateType, removalTemplate.deploymentFee
        );

        factory.setTemplate(templateId, removalTemplate);
        bytes32[] memory templateIds = factory.templateIds();
        for (uint256 i = 0; i < templateIds.length; i++) {
            assertNotEq(templateIds[i], templateId);
        }
    }
}
