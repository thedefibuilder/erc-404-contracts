// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { BaseTest } from "test/Base.t.sol";
import { Deployments } from "script/DeploymentsLib.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";

abstract contract TemplateFactoryTest is BaseTest {
    TemplateFactory public factory;

    function setUp() public virtual override {
        super.setUp();

        factory = Deployments.deployTemplateFactory(users.vault, users.admin);
    }
}
