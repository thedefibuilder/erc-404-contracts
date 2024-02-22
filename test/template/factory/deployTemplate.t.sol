// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Deployments } from "script/DeploymentsLib.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { MockSimpleContractTemplate } from "test/mocks/SimpleContractTemplate.t.sol";
import { MockProxyCloneTemplate } from "test/mocks/ProxyCloneTemplate.t.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_deployTemplate is TemplateFactoryTest {
    uint88 public constant deploymentFee = 100;

    bytes32 public contractTemplateId = bytes32(uint256(1));
    bytes32 public proxyTemplateId = bytes32(uint256(2));
    bytes32 public invalidTemplateId = bytes32(uint256(3));
    TemplateFactory.Template public contractTemplate;
    TemplateFactory.Template public proxyTemplate;
    TemplateFactory.Template public invalidTemplate;

    function setUp() public override {
        super.setUp();

        contractTemplate = TemplateFactory.Template({
            implementation: Deployments.deployCodePointer(type(MockSimpleContractTemplate).creationCode),
            templateType: TemplateFactory.TemplateType.SimpleContract,
            deploymentFee: deploymentFee
        });

        proxyTemplate = TemplateFactory.Template({
            implementation: address(new MockProxyCloneTemplate()),
            templateType: TemplateFactory.TemplateType.ProxyClone,
            deploymentFee: deploymentFee
        });

        invalidTemplate = TemplateFactory.Template({
            implementation: address(0),
            templateType: TemplateFactory.TemplateType.SimpleContract,
            deploymentFee: deploymentFee
        });

        vm.startPrank(users.admin);
        factory.setTemplate(contractTemplateId, contractTemplate);
        factory.setTemplate(proxyTemplateId, proxyTemplate);
        factory.setTemplate(invalidTemplateId, invalidTemplate);
    }

    function test_RevertsIf_ImplementationNotFound() public {
        vm.expectRevert(TemplateFactory.ImplementationNotFound.selector);

        factory.deployTemplate(invalidTemplateId, "");
    }

    function test_RevertsIf_InsufficientDeploymentFee() public {
        vm.expectRevert(TemplateFactory.InsufficientDeploymentFee.selector);

        factory.deployTemplate{ value: deploymentFee - 1 }(contractTemplateId, "");
    }

    function testFuzz_SimpleContract_Deploys(uint256 value) public {
        vm.startPrank(users.stranger);
        bytes memory constructorArgs = abi.encode(value);
        uint256 totalDeploymentsBefore = factory.totalDeployments();
        uint256 totalUserDeploymentsBefore = factory.deploymentsOf(users.stranger).length;

        vm.expectEmit(true, false, true, false);
        emit TemplateFactory.TemplateDeployed(contractTemplateId, address(0), users.stranger);

        address instance = factory.deployTemplate{ value: deploymentFee }(contractTemplateId, constructorArgs);

        assertEq(MockSimpleContractTemplate(instance).value(), value);
        assertEq(factory.totalDeployments(), totalDeploymentsBefore + 1);
        assertEq(factory.deploymentsOf(users.stranger).length, totalUserDeploymentsBefore + 1);
        for (uint256 i = 0; i < factory.deploymentsOf(users.stranger).length; i++) {
            assertEq(factory.deploymentsOf(users.stranger)[i].templateId, contractTemplateId);
            assertEq(factory.deploymentsOf(users.stranger)[i].instance, instance);
        }
    }

    function testFuzz_ProxyClone_Deploys(uint256 value) public {
        vm.startPrank(users.stranger);
        bytes memory initData = abi.encodeWithSelector(MockProxyCloneTemplate.initialize.selector, value);
        uint256 totalDeploymentsBefore = factory.totalDeployments();
        uint256 totalUserDeploymentsBefore = factory.deploymentsOf(users.stranger).length;

        vm.expectEmit(true, false, true, false);
        emit TemplateFactory.TemplateDeployed(proxyTemplateId, address(0), users.stranger);

        address instance = factory.deployTemplate{ value: deploymentFee }(proxyTemplateId, initData);

        assertEq(MockProxyCloneTemplate(instance).value(), value);
        assertEq(factory.totalDeployments(), totalDeploymentsBefore + 1);
        assertEq(factory.deploymentsOf(users.stranger).length, totalUserDeploymentsBefore + 1);
        for (uint256 i = 0; i < factory.deploymentsOf(users.stranger).length; i++) {
            assertEq(factory.deploymentsOf(users.stranger)[i].templateId, proxyTemplateId);
            assertEq(factory.deploymentsOf(users.stranger)[i].instance, instance);
        }
    }

    function testFuzz_FeeIsHandledProperly(uint256 fee) public {
        vm.startPrank(users.stranger);
        bytes memory constructorArgs = abi.encode(0);
        uint256 vaultBalanceBefore = factory.vault().balance;
        uint256 senderBalanceBefore = address(users.stranger).balance;
        vm.assume(fee < senderBalanceBefore - deploymentFee);

        factory.deployTemplate{ value: deploymentFee + fee }(contractTemplateId, constructorArgs);

        assertEq(factory.vault().balance, vaultBalanceBefore + deploymentFee);
        assertEq(address(users.stranger).balance, senderBalanceBefore - deploymentFee);
    }
}
