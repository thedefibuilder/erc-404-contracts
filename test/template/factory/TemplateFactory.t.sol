// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { BaseTest } from "test/Base.t.sol";
import { Deployments } from "script/Deployments.sol";
import { ERC404LegacyFactory } from "src/legacy/ERC404LegacyFactory.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";

abstract contract TemplateFactoryTest is BaseTest {
    TemplateFactory public factory;
    ERC404LegacyFactory public legacyFactory;

    function setUp() public virtual override {
        super.setUp();

        // Intentionally inversed admin and vault for legacy factory constructor.
        legacyFactory = new ERC404LegacyFactory(users.admin, 0.1e18, users.vault, ERC404LegacyFactory.FreePeriod(0, 0));
        factory = Deployments.deployTemplateFactory(users.vault, users.admin, address(legacyFactory));
    }
}
