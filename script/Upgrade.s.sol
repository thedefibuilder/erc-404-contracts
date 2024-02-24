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

contract Upgrade is BaseScript {
    using ShortStrings for *;
    using SafeCast for uint256;

    TemplateFactory public factory;

    function run() public broadcast {
        factory = TemplateFactory(config.templateFactory);

        TemplateFactory newVersion =
            new TemplateFactory(config.legacyFactory, ShortString.unwrap("ERC404Legacy".toShortString()));

        Template legacyTemplate = toTemplate(config.legacyFactory, TemplateType.LegacyFactory, 0);

        factory.upgradeToAndCall(address(newVersion), "");
        factory.setTemplate(factory.LEGACY_TEMPLATE_ID(), legacyTemplate);

        assert(address(factory.LEGACY_FACTORY()) == config.legacyFactory);
    }
}
