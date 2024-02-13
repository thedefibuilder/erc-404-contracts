// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { BaseTest } from "test/Base.t.sol";
import { Factory } from "src/factory/Factory.sol";

contract FactoryTest is BaseTest {
    Factory public factory;
    uint128 public initialDeploymentFee = 0.1e18;
    Factory.FreePeriod public initialfreePeriod = Factory.FreePeriod({ start: uint64(block.timestamp), end: 0 });

    function setUp() public override {
        super.setUp();

        factory = new Factory(users.vault, initialDeploymentFee, users.admin, initialfreePeriod);
    }
}
