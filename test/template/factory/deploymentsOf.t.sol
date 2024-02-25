// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Deployments } from "script/Deployments.sol";
import { MockSimpleContractTemplate } from "test/mocks/SimpleContractTemplate.t.sol";
import { Template, TemplateType, toTemplate } from "src/types/Template.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_deploymentsOf is TemplateFactoryTest {
    bytes32 public contractTemplateId = bytes32(uint256(1));
    Template public contractTemplate;

    uint256 public legacyDeployments = 10;
    uint256 public newDeployments = 10;

    function setUp() public override {
        super.setUp();

        contractTemplate = toTemplate(
            Deployments.deployCodePointer(type(MockSimpleContractTemplate).creationCode), TemplateType.SimpleContract, 0
        );

        vm.startPrank(users.admin);
        factory.setTemplate(contractTemplateId, contractTemplate);
    }

    function test_CombinesLegacyDeployments() public {
        vm.startPrank(users.deployer);
        for (uint256 i = 0; i < legacyDeployments; i++) {
            legacyFactory.deployERC404{ value: legacyFactory.deploymentFee() }("name", "symbol", "baseURI", 100);
        }
        assertEq(factory.deploymentsOf(users.deployer).length, legacyDeployments);

        for (uint256 i = 0; i < newDeployments; i++) {
            factory.deployTemplate(contractTemplateId, abi.encode("name", "symbol", "baseURI", 100));
        }

        assertEq(factory.deploymentsOf(users.deployer).length, legacyDeployments + newDeployments);
        for (uint256 i = 0; i < legacyDeployments; i++) {
            assertEq(factory.deploymentsOf(users.deployer)[i].instance, legacyFactory.deploymentsOf(users.deployer)[i]);
            assertEq(factory.deploymentsOf(users.deployer)[i].templateId, factory.LEGACY_TEMPLATE_ID());
        }
    }
}
