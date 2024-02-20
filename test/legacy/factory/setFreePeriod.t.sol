// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@oz/access/Ownable.sol";
import { ERC404LegacyFactoryTest } from "./ERC404LegacyFactory.t.sol";
import { ERC404LegacyFactory } from "src/legacy/ERC404LegacyFactory.sol";

contract ERC404LegacyFactory_setFreePeriod is ERC404LegacyFactoryTest {
    function test_RevertsIf_NotOwner() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));
        factory.setFreePeriod(ERC404LegacyFactory.FreePeriod({ start: 0, end: 0 }));
    }

    function test_RevertsIf_StartBiggerThanEnd(uint64 start, uint64 end) public {
        vm.assume(start > end && end > 0);

        vm.expectRevert(ERC404LegacyFactory.StartTimeTooBig.selector);
        vm.startPrank(users.admin);
        factory.setFreePeriod(ERC404LegacyFactory.FreePeriod({ start: start, end: end }));
    }

    function test_RevertsIf_EndSmallerThanBlockTimestamp(uint64 start, uint64 end) public {
        vm.assume(start < end && end < block.timestamp && end > 0);

        vm.expectRevert(ERC404LegacyFactory.EndTimeTooSmall.selector);
        vm.startPrank(users.admin);
        factory.setFreePeriod(ERC404LegacyFactory.FreePeriod({ start: start, end: end }));
    }

    function test_ChangesFreePeriod() public {
        ERC404LegacyFactory.FreePeriod memory newFreePeriod =
            ERC404LegacyFactory.FreePeriod({ start: 0, end: type(uint64).max });

        vm.expectEmit(address(factory));
        emit ERC404LegacyFactory.FreePeriodChanged(newFreePeriod);

        vm.startPrank(users.admin);
        factory.setFreePeriod(newFreePeriod);

        assertEq(factory.freePeriod().start, newFreePeriod.start);
        assertEq(factory.freePeriod().end, newFreePeriod.end);
        assertEq(factory.deploymentFeeForUser(users.stranger), 0);
    }
}
