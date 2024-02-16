// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { Factory } from "src/factory/Factory.sol";
import { console } from "forge-std/src/console.sol";

contract Interact is BaseScript {
    Factory public factory = Factory(0x6bdc4c9FC3AE70c118550Dba6acd36d86C70298E);

    Factory.FreePeriod public freePeriod = Factory.FreePeriod({ start: 0, end: 1_708_088_400 });

    function run() public broadcast {
        factory.setDeploymentFee(0.1e18);
    }
}
