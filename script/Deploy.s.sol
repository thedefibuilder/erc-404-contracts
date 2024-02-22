// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ShortStrings, ShortString } from "@oz/utils/ShortStrings.sol";
import { console } from "forge-std/src/console.sol";
import { Deployments } from "script/DeploymentsLib.sol";
import { BaseScript } from "./Base.s.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { ERC404ManagedURI } from "src/templates/ERC404ManagedURI.sol";
import { toTemplate, TemplateType, Template } from "src/types/Template.sol";

contract Deploy is BaseScript {
    using ShortStrings for *;

    TemplateFactory public factory;

    function run() public broadcast {
        // Polygon = 30e18 MATIC
        // BNB = 0.1e18 BNB
        // LINEA & ARBITRUM = 0.01e18 ETH
        factory = Deployments.deployTemplateFactory(0x5B3B2c5dfCAfeB4bf46Cfc3141e36E793f4C6fcd, broadcaster);

        Template erc404Template = toTemplate(
            Deployments.deployCodePointer(type(ERC404ManagedURI).creationCode), TemplateType.SimpleContract, 0.01e18
        );

        bytes32 templateId = ShortString.unwrap("ERC404Optimized".toShortString());
        factory.setTemplate(templateId, erc404Template);

        console.log("Deployed TemplateFactory at", address(factory));
    }
}
