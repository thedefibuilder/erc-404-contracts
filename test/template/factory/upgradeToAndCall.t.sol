// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@oz/access/Ownable.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_upgradeToAndCall is TemplateFactoryTest {
    function test_RevertsIf_Unauthorized() public {
        vm.startPrank(users.stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));

        factory.upgradeToAndCall(users.stranger, "");
    }
}
