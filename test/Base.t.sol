// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

contract BaseTest is PRBTest, StdCheats {
    struct Users {
        address admin;
        address stranger;
        address vault;
    }

    Users public users;

    function setUp() public virtual {
        users = Users({ admin: createUser("admin"), stranger: createUser("stranger"), vault: createUser("vault") });

        vm.startPrank(users.admin);
    }

    function createUser(string memory name) public returns (address account) {
        account = makeAddr(name);
        deal(account, type(uint256).max);
    }
}
