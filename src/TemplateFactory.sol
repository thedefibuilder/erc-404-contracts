// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { UUPSUpgradeable } from "@ozu/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@ozu/access/OwnableUpgradeable.sol";
import { Clones } from "@oz/proxy/Clones.sol";
import { Create2 } from "@oz/utils/Create2.sol";
import { Address } from "@oz/utils/Address.sol";
import { EnumerableSet } from "@oz/utils/structs/EnumerableSet.sol";
import { SSTORE2 } from "@solmate/utils/SSTORE2.sol";
import { Template, TemplateType } from "src/types/Template.sol";

contract TemplateFactory is OwnableUpgradeable, UUPSUpgradeable {
    using Address for *;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Clones for address;
    using SSTORE2 for address;

    error ImplementationNotFound();
    error TemplateNotSupported();
    error InsufficientDeploymentFee();

    event VaultSet(address indexed newVault);
    event TemplateSet(bytes32 indexed id, address implementation, TemplateType templateType, uint88 fee);
    event TemplateDeployed(bytes32 indexed id, address indexed instance, address indexed user);

    struct Deployment {
        bytes32 templateId;
        address instance;
    }

    address public vault;
    uint96 public totalDeployments;

    mapping(bytes32 id => Template template) private _templates;
    mapping(address user => Deployment[] deployments) private _deploymentsOf;
    EnumerableSet.Bytes32Set private _templateIds;

    constructor() {
        _disableInitializers();
    }

    function initialize(address vault_, address admin) external initializer {
        __Ownable_init(admin);
        _setVault(vault_);
    }

    /// @notice Sets a template, used both for upserting and deleting templates.
    function setTemplate(bytes32 id, Template template) external onlyOwner {
        (address implementation, TemplateType templateType, uint88 deploymentFee) = template.unwrap();

        _templates[id] = template;
        if (implementation == address(0)) {
            _templateIds.remove(id);
        } else {
            _templateIds.add(id);
        }

        emit TemplateSet(id, implementation, templateType, deploymentFee);
    }

    /// @notice Sets the vault address.
    function setVault(address newVault) external onlyOwner {
        _setVault(newVault);
    }

    /// @notice Deploys a template for the calling user.
    /// @param templateId The id of the template to deploy
    /// @param initData The data to be used in the initializer/constructor of deployed contract.
    /// @dev For proxy clones, initData should include selector.
    function deployTemplate(bytes32 templateId, bytes calldata initData) external payable returns (address instance) {
        Template template = _templates[templateId];
        (address implementation, TemplateType templateType, uint88 deploymentFee) = template.unwrap();

        // Check
        if (implementation.code.length == 0) revert ImplementationNotFound();
        if (msg.value < deploymentFee) revert InsufficientDeploymentFee();

        // Effects
        totalDeployments++;
        if (templateType == TemplateType.SimpleContract) {
            instance = _deploySimpleContract(implementation, initData);
        } else if (templateType == TemplateType.ProxyClone) {
            instance = _deployProxyClone(implementation, initData);
        } else {
            revert TemplateNotSupported();
        }
        _deploymentsOf[msg.sender].push(Deployment(templateId, instance));
        emit TemplateDeployed(templateId, instance, msg.sender);

        // Interactions
        if (deploymentFee > 0) {
            payable(vault).sendValue(deploymentFee);
        }
        if (msg.value > deploymentFee) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - deploymentFee);
            }
        }
    }

    /// @notice Returns the template data given a specific id.
    function getTemplate(bytes32 templateId)
        external
        view
        returns (address implementation, TemplateType templateType, uint88 deploymentFee)
    {
        return _templates[templateId].unwrap();
    }

    /// @notice Returns all the deployments of a specific user.
    function deploymentsOf(address user) external view returns (Deployment[] memory) {
        return _deploymentsOf[user];
    }

    /// @notice Returns all the templateIds that are available.
    function templateIds() external view returns (bytes32[] memory) {
        return _templateIds.values();
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
            bytecode = abi.encodePacked(bytecode, constructorArgs);
        }
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, totalDeployments));
        instance = Create2.deploy(0, salt, bytecode);
    }

    function _deployProxyClone(address implementation, bytes calldata initData) internal returns (address instance) {
        instance = implementation.clone();
        if (initData.length > 0) {
            instance.functionCall(initData);
        }
    }

    function _setVault(address newVault) internal {
        vault = newVault;
        emit VaultSet(newVault);
    }
}
