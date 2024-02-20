// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { UUPSUpgradeable } from "@ozu/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@ozu/access/OwnableUpgradeable.sol";

contract TemplateFactory is OwnableUpgradeable, UUPSUpgradeable {
    error TemplateNotSupported();
    error TemplateNotFound();

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
    function setTemplate(bytes32 templateId, Template memory template) external onlyOwner {
        _templates[templateId] = template;

        emit TemplateSet(templateId, template.implementation, template.templateType, template.deploymentFee);
    }

    /// @notice Deploys a template for the calling user.
    function deployTemplate(bytes32 templateId, bytes calldata initData) external returns (address instance) {
        Template memory template = _templates[templateId];
        if (template.implementation == address(0)) revert TemplateNotFound();

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
        // solhint-disable-previous-line no-empty-blocks
    }

    function _deployProxyClone(address implementation, bytes calldata initData) internal returns (address instance) {
        // solhint-disable-previous-line no-empty-blocks
    }
}
