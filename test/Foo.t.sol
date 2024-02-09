// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Base is PRBTest, StdCheats {
    function setUp() public virtual {
        // deploy here
    }
}
