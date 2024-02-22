// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Strings } from "@oz/utils/Strings.sol";
import { Ownable } from "@oz/access/Ownable.sol";
import { ERC404ManagedURI } from "src/templates/ERC404ManagedURI.sol";
import { ERC404ManagedURITest } from "./ERC404ManagedURI.t.sol";

contract ERC404ManagedURI_setBaseURI is ERC404ManagedURITest {
    using Strings for uint256;

    function setUp() public override {
        super.setUp();

        vm.startPrank(users.deployer);
        erc404.mint(users.admin, 1000e18);
    }

    function test_RevertsIf_Unauthorized() public {
        vm.startPrank(users.stranger);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));

        erc404.setBaseURI("https://example.com/");
    }

    function test_SetsBaseURI() public {
        string memory newBaseURI = "https://new.example.com/";
        uint256 minted = erc404.minted();

        vm.expectEmit(address(erc404));
        emit ERC404ManagedURI.BatchMetadataUpdate(1, minted);

        erc404.setBaseURI(newBaseURI);

        for (uint256 i = 1; i <= minted; i++) {
            assertEq(erc404.tokenURI(i), string.concat(newBaseURI, i.toString()));
        }
    }
}
