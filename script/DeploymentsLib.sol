// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC1967Proxy } from "@oz/proxy/ERC1967/ERC1967Proxy.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";

library Deployments {
    function deployTemplateFactory(address vault, address admin) public returns (TemplateFactory) {
        bytes memory data = abi.encodeWithSelector(TemplateFactory.initialize.selector, vault, admin);
        TemplateFactory factory = new TemplateFactory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(factory), data);
        return TemplateFactory(address(proxy));
    }
}
