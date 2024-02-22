// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

type Template is bytes32;

using Templates for Template global;

/// @notice Types of templates. More can be added.
/// 1. Simple Contract, address stores creation code using SSTORE2.
/// 2. Proxy, address stores implementation.
enum TemplateType {
    SimpleContract,
    ProxyClone
}

function toTemplate(address implementation, TemplateType templateType, uint88 deploymentFee) pure returns (Template) {
    uint256 implementationBits = uint256(uint160(implementation)) << 96;
    uint256 templateTypeBits = uint256(uint8(templateType)) << 88;
    uint256 deploymentFeeBits = uint256(deploymentFee);

    return Template.wrap(bytes32(implementationBits + templateTypeBits + deploymentFeeBits));
}

library Templates {
    function unwrap(Template template) internal pure returns (address, TemplateType, uint88) {
        return (implementation(template), templateType(template), deploymentFee(template));
    }

    function implementation(Template template) internal pure returns (address) {
        return address(uint160(uint256(Template.unwrap(template)) >> 96));
    }

    function templateType(Template template) internal pure returns (TemplateType) {
        return TemplateType(uint8(uint256(Template.unwrap(template)) >> 88));
    }

    function deploymentFee(Template template) internal pure returns (uint88) {
        return uint88(uint256(Template.unwrap(template)));
    }
}
