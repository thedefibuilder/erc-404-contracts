// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC404Test } from "./ERC404.t.sol";
import { IERC404Legacy } from "src/legacy/IERC404Legacy.sol";

contract ERC404Test_setApprovalForAll is ERC404Test {
    function test_setsApprovalForAll() public {
        vm.startPrank(users.deployer);

        vm.expectEmit(address(erc404));
        emit IERC404Legacy.ApprovalForAll(users.deployer, users.stranger, true);
        erc404.setApprovalForAll(users.stranger, true);

        assertTrue(erc404.isApprovedForAll(users.deployer, users.stranger));
    }
}