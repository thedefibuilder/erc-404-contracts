// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC404Test } from "test/erc404/ERC404.t.sol";
import { MockERC721Receiver, ERC721Holder } from "test/mocks/ERC721Receiver.t.sol";

contract ERC404Test_safeTransferFrom is ERC404Test {
    MockERC721Receiver public mockReceiver;

    function setUp() public override {
        super.setUp();

        mockReceiver = new MockERC721Receiver();

        vm.startPrank(users.deployer);
        erc404.mint(users.deployer, 500e18);
    }

    function test_MakesERC721ReceiverCall(bytes memory data) public {
        bytes memory callData =
            abi.encodeWithSelector(ERC721Holder.onERC721Received.selector, users.deployer, users.deployer, 1, data);
        vm.expectCall(address(mockReceiver), callData);

        erc404.safeTransferFrom(users.deployer, address(mockReceiver), 1, data);
    }
}
