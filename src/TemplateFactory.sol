// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { UUPSUpgradeable } from "@ozu/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@ozu/access/OwnableUpgradeable.sol";
import { Clones } from "@oz/proxy/Clones.sol";
import { Create2 } from "@oz/utils/Create2.sol";
import { Address } from "@oz/utils/Address.sol";
import { SSTORE2 } from "@solmate/utils/SSTORE2.sol";

contract TemplateFactory is OwnableUpgradeable, UUPSUpgradeable {
    using Clones for address;
    using Address for address;
    using SSTORE2 for address;

    error ImplementationNotFound();
    error TemplateNotSupported();

    event TemplateSet(bytes32 indexed id, address indexed implementation, TemplateType templateType, uint88 fee);
    event TemplateDeployed(bytes32 indexed id, address indexed instance, address indexed user);

    /// @notice Types of templates. More can be added.
    /// 1. Simple Contract, address stores bytecode
    /// 2. Proxy, address stores implementation
    enum TemplateType {
        SimpleContract,
        ProxyClone
    }

    struct Template {
        address implementation;
        TemplateType templateType;
        uint88 deploymentFee;
    }

    bytes32[] public templateIds;
    mapping(bytes32 id => Template template) internal _templates;

    /// @notice Sets a template, used both for upserting and deleting templates.
    function setTemplate(bytes32 templateId, Template calldata template) external onlyOwner {
        _templates[templateId] = template;

        emit TemplateSet(templateId, template.implementation, template.templateType, template.deploymentFee);
    }

    /// @notice Deploys a template for the calling user.
    /// @param templateId The id of the template to deploy
    /// @param initData The data to be used in the initializer/constructor of deployed contract.
    /// @dev For proxy clones, initData should include selector.
    function deployTemplate(bytes32 templateId, bytes calldata initData) external returns (address instance) {
        Template memory template = _templates[templateId];
        // This reverts if implementation == address(0) as well.
        if (template.implementation.code.length == 0) revert ImplementationNotFound();

        if (template.templateType == TemplateType.SimpleContract) {
            instance = _deploySimpleContract(template.implementation, initData);
        } else if (template.templateType == TemplateType.ProxyClone) {
            instance = _deployProxyClone(template.implementation, initData);
        } else {
            revert TemplateNotSupported();
        }

        emit TemplateDeployed(templateId, instance, msg.sender);
    }

    /// @notice Returns the template data given a specific id.
    function getTemplate(bytes32 templateId) external view returns (Template memory) {
        return _templates[templateId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _deploySimpleContract(
        address codePointer,
        bytes calldata constructorArgs
    )
        internal
        returns (address instance)
    {
        bytes memory bytecode = codePointer.read();
        if (constructorArgs.length > 0) {
            bytecode = abi.encode(bytecode, constructorArgs);
        }
        bytes32 salt = keccak256(abi.encode(msg.sender, block.timestamp));
        instance = Create2.deploy(0, salt, bytecode);
    }

    function _deployProxyClone(address implementation, bytes calldata initData) internal returns (address instance) {
        instance = implementation.clone();
        if (initData.length > 0) {
            instance.functionCall(initData);
        }
    }
}
