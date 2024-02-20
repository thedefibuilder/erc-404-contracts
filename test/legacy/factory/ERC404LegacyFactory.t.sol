// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { BaseTest } from "test/Base.t.sol";
import { ERC404LegacyFactory } from "src/legacy/ERC404LegacyFactory.sol";

contract ERC404LegacyFactoryTest is BaseTest {
    ERC404LegacyFactory public factory;
    uint128 public initialDeploymentFee = 0.1e18;
    ERC404LegacyFactory.FreePeriod public initialfreePeriod =
        ERC404LegacyFactory.FreePeriod({ start: uint64(block.timestamp), end: 0 });

    function setUp() public override {
        super.setUp();

        factory = new ERC404LegacyFactory(users.vault, initialDeploymentFee, users.admin, initialfreePeriod);
    }
}
