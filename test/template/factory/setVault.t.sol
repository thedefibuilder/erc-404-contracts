// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@oz/access/Ownable.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_setVault is TemplateFactoryTest {
    function test_ReversIf_Unauthorized() public {
        vm.startPrank(users.stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));

        factory.setVault(users.stranger);
    }

    function test_setsVault() public {
        vm.startPrank(users.admin);

        vm.expectEmit(address(factory));
        emit TemplateFactory.VaultSet(users.admin);

        factory.setVault(users.admin);

        assertEq(factory.vault(), users.admin);
    }
}
