// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { BaseScript } from "./Base.s.sol";

import { Factory } from "src/factory/Factory.sol";

contract Deploy is BaseScript {
    Factory public factory;

    function run() public broadcast {
        factory = new Factory(broadcaster, 0.01e18, broadcaster);
    }
}
