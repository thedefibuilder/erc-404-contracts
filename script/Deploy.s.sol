// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ShortStrings, ShortString } from "@oz/utils/ShortStrings.sol";
import { SafeCast } from "@oz/utils/math/SafeCast.sol";
import { console } from "forge-std/src/console.sol";
import { Deployments } from "script/Deployments.sol";
import { BaseScript } from "./Base.s.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { ERC404ManagedURI } from "src/templates/ERC404ManagedURI.sol";
import { toTemplate, TemplateType, Template } from "src/types/Template.sol";

contract Deploy is BaseScript {
    using ShortStrings for *;
    using SafeCast for uint256;

    TemplateFactory public factory;

    function run() public broadcast {
        factory = Deployments.deployTemplateFactory(config.vault, config.admin, config.legacyFactory);

        Template erc404Template = toTemplate(
            Deployments.deployCodePointer(type(ERC404ManagedURI).creationCode),
            TemplateType.SimpleContract,
            config.deploymentFee.toUint88()
        );
        Template legacyTemplate = toTemplate(config.legacyFactory, TemplateType.LegacyFactory, 0);

        factory.setTemplate(ShortString.unwrap("ERC404Optimized".toShortString()), erc404Template);
        factory.setTemplate(factory.LEGACY_TEMPLATE_ID(), legacyTemplate);

        console.log("Deployed TemplateFactory at", address(factory));
    }
}
