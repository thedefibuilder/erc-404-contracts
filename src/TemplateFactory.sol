// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { UUPSUpgradeable } from "@ozu/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@ozu/access/OwnableUpgradeable.sol";
import { Clones } from "@oz/proxy/Clones.sol";
import { Create2 } from "@oz/utils/Create2.sol";
import { Address } from "@oz/utils/Address.sol";
import { EnumerableSet } from "@oz/utils/structs/EnumerableSet.sol";
import { SSTORE2 } from "@solmate/utils/SSTORE2.sol";
import { SafeCast } from "@oz/utils/math/SafeCast.sol";
import { Template, TemplateType } from "src/types/Template.sol";
import { ERC404LegacyFactory, ERC404LegacyManagedURI } from "src/legacy/ERC404LegacyFactory.sol";

contract TemplateFactory is OwnableUpgradeable, UUPSUpgradeable {
    using Address for *;
    using SafeCast for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Clones for address;
    using SSTORE2 for address;

    error ZeroAddress();
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

    bytes32 public immutable LEGACY_TEMPLATE_ID;
    ERC404LegacyFactory public immutable LEGACY_FACTORY;

    mapping(bytes32 id => Template template) private _templates;
    mapping(address user => Deployment[] deployments) private _deploymentsOf;
    EnumerableSet.Bytes32Set private _templateIds;

    constructor(address legacyFactory, bytes32 legacyTemplateId) {
        LEGACY_FACTORY = ERC404LegacyFactory(legacyFactory);
        LEGACY_TEMPLATE_ID = legacyTemplateId;
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
        (address implementation, TemplateType templateType, uint88 deploymentFee) = getTemplate(templateId);

        // Checks
        if (implementation.code.length == 0) revert ImplementationNotFound();
        if (msg.value < deploymentFee) revert InsufficientDeploymentFee();

        // Effects
        totalDeployments++;
        if (templateType == TemplateType.SimpleContract) {
            instance = _deploySimpleContract(implementation, initData);
        } else if (templateType == TemplateType.ProxyClone) {
            instance = _deployProxyClone(implementation, initData);
        } else if (templateType == TemplateType.LegacyFactory) {
            instance = _deployERC404Legacy(implementation, initData, deploymentFee);
        } else {
            revert TemplateNotSupported();
        }
        _deploymentsOf[msg.sender].push(Deployment(templateId, instance));
        emit TemplateDeployed(templateId, instance, msg.sender);

        // Interactions
        // In legacy deployments fee is already handled by the factory.
        if (deploymentFee > 0 && templateId != LEGACY_TEMPLATE_ID) {
            payable(vault).sendValue(deploymentFee);
        }
        _refundUser(deploymentFee);
    }

    /// @notice Returns the template data given a specific id.
    function getTemplate(bytes32 templateId)
        public
        view
        returns (address implementation, TemplateType templateType, uint88 deploymentFee)
    {
        if (templateId == LEGACY_TEMPLATE_ID) {
            deploymentFee = uint256(LEGACY_FACTORY.deploymentFeeForUser(address(this))).toUint88();
            return (address(LEGACY_FACTORY), TemplateType.LegacyFactory, deploymentFee);
        }
        return _templates[templateId].unwrap();
    }

    /// @notice Returns all the deployments of a specific user.
    function deploymentsOf(address user) external view returns (Deployment[] memory) {
        if (address(LEGACY_FACTORY) != address(0)) {
            address[] memory legacyDeployments = LEGACY_FACTORY.deploymentsOf(user);
            uint256 legacyDeploymentsLength = legacyDeployments.length;
            uint256 deploymentsLength = _deploymentsOf[user].length;
            Deployment[] memory allDeployments = new Deployment[](legacyDeploymentsLength + deploymentsLength);
            for (uint256 i = 0; i < legacyDeploymentsLength; i++) {
                allDeployments[i] = Deployment(LEGACY_TEMPLATE_ID, legacyDeployments[i]);
            }
            for (uint256 i = 0; i < deploymentsLength; i++) {
                allDeployments[i + legacyDeploymentsLength] = _deploymentsOf[user][i];
            }
            return allDeployments;
        }
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

    function _deployERC404Legacy(
        address,
        bytes calldata constructorArgs,
        uint256 deploymentFee
    )
        internal
        returns (address instance)
    {
        (string memory name, string memory symbol, string memory baseURI, uint256 totalNFTSupply) =
            abi.decode(constructorArgs, (string, string, string, uint256));
        instance = LEGACY_FACTORY.deployERC404{ value: deploymentFee }(name, symbol, baseURI, totalNFTSupply);
        ERC404LegacyManagedURI(instance).transferOwnership(msg.sender);
    }

    function _setVault(address newVault) internal {
        if (newVault == address(0)) revert ZeroAddress();
        vault = newVault;
        emit VaultSet(newVault);
    }

    function _refundUser(uint256 neededAmount) internal {
        if (msg.value > neededAmount) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - neededAmount);
            }
        }
    }
}
