// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Initializable } from "@oz/proxy/utils/Initializable.sol";
import { ERC1967Utils } from "@oz/proxy/ERC1967/ERC1967Utils.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";
import { TemplateFactoryTest } from "./TemplateFactory.t.sol";

contract TemplateFactory_initialize is TemplateFactoryTest {
    function test_initialize() public {
        assertEq(factory.vault(), users.vault);
        assertEq(factory.owner(), users.admin);
    }

    function test_RevertsIf_Reinitializes() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);

        factory.initialize(users.vault, users.admin);
    }

    function test_RevertsIf_ImplementationIsInitialized() public {
        bytes32 erc1967Slot = ERC1967Utils.IMPLEMENTATION_SLOT;
        address implementation = address(bytes20(vm.load(address(factory), erc1967Slot) << 96));

        vm.expectRevert(Initializable.InvalidInitialization.selector);

        TemplateFactory(implementation).initialize(users.vault, users.admin);
    }
}
