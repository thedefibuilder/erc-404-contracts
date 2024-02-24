// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC404LegacyManagedURI } from "src/legacy/ERC404LegacyManagedURI.sol";
import { Deployments } from "script/Deployments.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { MockSimpleContractTemplate } from "test/mocks/SimpleContractTemplate.t.sol";
import { MockProxyCloneTemplate } from "test/mocks/ProxyCloneTemplate.t.sol";
import { toTemplate, TemplateType, Template } from "src/types/Template.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_deployTemplate is TemplateFactoryTest {
    // solhint-disable const-name-snakecase
    uint88 public constant deploymentFee = 100;
    string public constant name = "name";
    string public constant symbol = "symbol";
    string public constant baseURI = "baseURI";
    uint256 public constant totalNFTSupply = 100;

    bytes32 public contractTemplateId = bytes32(uint256(1));
    bytes32 public proxyTemplateId = bytes32(uint256(2));
    bytes32 public invalidTemplateId = bytes32(uint256(3));
    bytes32 public legacyTemplateId;
    Template public contractTemplate;
    Template public proxyTemplate;
    Template public legacyTemplate;
    Template public invalidTemplate;

    function setUp() public override {
        super.setUp();

        legacyTemplateId = factory.LEGACY_TEMPLATE_ID();
        contractTemplate = toTemplate(
            Deployments.deployCodePointer(type(MockSimpleContractTemplate).creationCode),
            TemplateType.SimpleContract,
            deploymentFee
        );

        proxyTemplate = toTemplate(address(new MockProxyCloneTemplate()), TemplateType.ProxyClone, deploymentFee);
        invalidTemplate = toTemplate(address(0), TemplateType.SimpleContract, deploymentFee);
        legacyTemplate =
            toTemplate(address(legacyFactory), TemplateType.LegacyFactory, uint88(legacyFactory.deploymentFee()));

        vm.startPrank(users.admin);
        factory.setTemplate(contractTemplateId, contractTemplate);
        factory.setTemplate(proxyTemplateId, proxyTemplate);
        factory.setTemplate(invalidTemplateId, invalidTemplate);
        factory.setTemplate(legacyTemplateId, legacyTemplate);
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
        vm.startPrank(users.deployer);
        bytes memory constructorArgs = abi.encode(value);
        uint256 totalDeploymentsBefore = factory.totalDeployments();
        uint256 totalUserDeploymentsBefore = factory.deploymentsOf(users.deployer).length;

        vm.expectEmit(true, false, true, false);
        emit TemplateFactory.TemplateDeployed(contractTemplateId, address(0), users.deployer);

        address instance = factory.deployTemplate{ value: deploymentFee }(contractTemplateId, constructorArgs);

        assertEq(MockSimpleContractTemplate(instance).value(), value);
        assertEq(factory.totalDeployments(), totalDeploymentsBefore + 1);
        assertEq(factory.deploymentsOf(users.deployer).length, totalUserDeploymentsBefore + 1);
        for (uint256 i = 0; i < factory.deploymentsOf(users.deployer).length; i++) {
            assertEq(factory.deploymentsOf(users.deployer)[i].templateId, contractTemplateId);
            assertEq(factory.deploymentsOf(users.deployer)[i].instance, instance);
        }
    }

    function testFuzz_ProxyClone_Deploys(uint256 value) public {
        vm.startPrank(users.deployer);
        bytes memory initData = abi.encodeWithSelector(MockProxyCloneTemplate.initialize.selector, value);
        uint256 totalDeploymentsBefore = factory.totalDeployments();
        uint256 totalUserDeploymentsBefore = factory.deploymentsOf(users.deployer).length;

        vm.expectEmit(true, false, true, false);
        emit TemplateFactory.TemplateDeployed(proxyTemplateId, address(0), users.deployer);

        address instance = factory.deployTemplate{ value: deploymentFee }(proxyTemplateId, initData);

        assertEq(MockProxyCloneTemplate(instance).value(), value);
        assertEq(factory.totalDeployments(), totalDeploymentsBefore + 1);
        assertEq(factory.deploymentsOf(users.deployer).length, totalUserDeploymentsBefore + 1);
        for (uint256 i = 0; i < factory.deploymentsOf(users.deployer).length; i++) {
            assertEq(factory.deploymentsOf(users.deployer)[i].templateId, proxyTemplateId);
            assertEq(factory.deploymentsOf(users.deployer)[i].instance, instance);
        }
    }

    function test_LegacyFactory_Deploys() public {
        vm.startPrank(users.deployer);
        bytes memory constructorArgs = abi.encode(name, symbol, baseURI, totalNFTSupply);
        uint256 totalDeploymentsBefore = factory.totalDeployments();
        uint256 totalUserDeploymentsBefore = factory.deploymentsOf(users.deployer).length;

        vm.expectEmit(true, false, true, false);
        emit TemplateFactory.TemplateDeployed(legacyTemplateId, address(0), users.deployer);

        address instance =
            factory.deployTemplate{ value: legacyFactory.deploymentFee() }(legacyTemplateId, constructorArgs);

        assertEq(factory.totalDeployments(), totalDeploymentsBefore + 1);
        assertEq(factory.deploymentsOf(users.deployer).length, totalUserDeploymentsBefore + 1);
        for (uint256 i = 0; i < factory.deploymentsOf(users.deployer).length; i++) {
            assertEq(factory.deploymentsOf(users.deployer)[i].templateId, legacyTemplateId);
            assertEq(factory.deploymentsOf(users.deployer)[i].instance, instance);
        }
        assertEq(ERC404LegacyManagedURI(instance).name(), name);
        assertEq(ERC404LegacyManagedURI(instance).symbol(), symbol);
        assertEq(ERC404LegacyManagedURI(instance).baseURI(), baseURI);
        assertEq(ERC404LegacyManagedURI(instance).totalSupply(), totalNFTSupply * 1e18);
        assertEq(ERC404LegacyManagedURI(instance).owner(), users.deployer);
    }

    function testFuzz_LegacyFactory_FeeIsHandledProperly(uint256 fee) public {
        vm.startPrank(users.deployer);
        bytes memory constructorArgs = abi.encode(name, symbol, baseURI, totalNFTSupply);
        uint256 vaultBalanceBefore = legacyFactory.vault().balance;
        uint256 senderBalanceBefore = address(users.deployer).balance;
        (,, uint88 legacyFee) = factory.getTemplate(legacyTemplateId);
        vm.assume(fee < senderBalanceBefore - legacyFee);

        factory.deployTemplate{ value: legacyFee + fee }(legacyTemplateId, constructorArgs);

        assertEq(legacyFactory.vault().balance, vaultBalanceBefore + legacyFee);
        assertEq(address(users.deployer).balance, senderBalanceBefore - legacyFee);
    }

    function testFuzz_FeeIsHandledProperly(uint256 fee) public {
        vm.startPrank(users.deployer);
        bytes memory constructorArgs = abi.encode(0);
        uint256 vaultBalanceBefore = factory.vault().balance;
        uint256 senderBalanceBefore = address(users.deployer).balance;
        vm.assume(fee < senderBalanceBefore - deploymentFee);

        factory.deployTemplate{ value: deploymentFee + fee }(contractTemplateId, constructorArgs);

        assertEq(factory.vault().balance, vaultBalanceBefore + deploymentFee);
        assertEq(address(users.deployer).balance, senderBalanceBefore - deploymentFee);
    }
}
