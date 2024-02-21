// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Initializable } from "@oz/proxy/utils/Initializable.sol";

contract MockProxyCloneTemplate is Initializable {
    uint256 public value;

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 value_) external initializer {
        value = value_;
    }
}
