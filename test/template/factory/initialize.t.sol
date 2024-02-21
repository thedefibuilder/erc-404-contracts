// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_initialize is TemplateFactoryTest {
    function test_initialize() public {
        assertEq(factory.vault(), users.vault);
        assertEq(factory.owner(), users.admin);
    }
}
