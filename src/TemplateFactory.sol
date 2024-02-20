// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { UUPSUpgradeable } from "@ozu/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@ozu/access/OwnableUpgradeable.sol";

contract TemplateFactory is OwnableUpgradeable, UUPSUpgradeable {
    function registerTemplate(bytes32 templateId) external { }

    function deployTemplate(bytes32 templateId) external returns (address) { }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // solhint-disable-previous-line no-empty-blocks
    }
}
