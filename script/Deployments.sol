// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ShortStrings, ShortString } from "@oz/utils/ShortStrings.sol";
import { SSTORE2 } from "@solmate/utils/SSTORE2.sol";
import { ERC1967Proxy } from "@oz/proxy/ERC1967/ERC1967Proxy.sol";
import { TemplateFactory } from "src/TemplateFactory.sol";

library Deployments {
    using ShortStrings for *;

    function deployTemplateFactory(
        address vault,
        address admin,
        address legacyFactory
    )
        internal
        returns (TemplateFactory)
    {
        bytes memory data = abi.encodeWithSelector(TemplateFactory.initialize.selector, vault, admin);
        TemplateFactory factory =
            new TemplateFactory(legacyFactory, ShortString.unwrap("ERC404 Legacy".toShortString()));
        ERC1967Proxy proxy = new ERC1967Proxy(address(factory), data);
        return TemplateFactory(address(proxy));
    }

    function deployCodePointer(bytes memory data) internal returns (address codePointer) {
        codePointer = SSTORE2.write(data);
    }
}
