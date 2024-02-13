// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { Factory } from "src/factory/Factory.sol";

contract Deploy is BaseScript {
    Factory public factory;

    function run() public broadcast {
        Factory.FreePeriod memory freePeriod =
            Factory.FreePeriod({ start: uint64(block.timestamp), end: uint64(block.timestamp + 1 days) });
        factory = new Factory(broadcaster, 0.01e18, broadcaster, freePeriod);
    }
}
