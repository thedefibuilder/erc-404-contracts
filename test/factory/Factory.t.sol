// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { BaseTest } from "test/Base.t.sol";
import { Factory } from "src/factory/Factory.sol";

contract FactoryTest is BaseTest {
    Factory public factory;
    uint256 public initialDeploymentFee = 0.01e18;

    function setUp() public override {
        super.setUp();

        factory = new Factory(users.vault, initialDeploymentFee, users.admin);
    }
}
