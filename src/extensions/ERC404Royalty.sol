// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.23;

import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC404 } from "src/ERC404.sol";

abstract contract ERC404Royalty is ERC404, ERC2981 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC404, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
