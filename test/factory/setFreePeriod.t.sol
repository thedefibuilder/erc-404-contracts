// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FactoryTest } from "test/factory/Factory.t.sol";
import { Factory } from "src/factory/Factory.sol";

contract Factory_setFreePeriod is FactoryTest {
    function test_RevertsIf_NotOwner() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));
        factory.setFreePeriod(Factory.FreePeriod({ start: 0, end: 0 }));
    }

    function test_RevertsIf_StartBiggerThanEnd(uint64 start, uint64 end) public {
        vm.assume(start > end && end > 0);

        vm.expectRevert(Factory.StartTimeTooBig.selector);
        vm.startPrank(users.admin);
        factory.setFreePeriod(Factory.FreePeriod({ start: start, end: end }));
    }

    function test_RevertsIf_EndSmallerThanBlockTimestamp(uint64 start, uint64 end) public {
        vm.assume(start < end && end < block.timestamp && end > 0);

        vm.expectRevert(Factory.EndTimeTooSmall.selector);
        vm.startPrank(users.admin);
        factory.setFreePeriod(Factory.FreePeriod({ start: start, end: end }));
    }

    function test_ChangesFreePeriod() public {
        Factory.FreePeriod memory newFreePeriod = Factory.FreePeriod({ start: 0, end: 0 });

        vm.expectEmit(address(factory));
        emit Factory.FreePeriodChanged(newFreePeriod);

        vm.startPrank(users.admin);
        factory.setFreePeriod(newFreePeriod);

        assertEq(factory.freePeriod().start, newFreePeriod.start);
        assertEq(factory.freePeriod().end, newFreePeriod.end);
    }
}
