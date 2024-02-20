// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC404Test } from "./ERC404.t.sol";
import { ERC404LegacyManagedURI } from "src/legacy/ERC404LegacyManagedURI.sol";

contract ERC404Test_setBaseURI is ERC404Test {
    using Strings for uint256;

    function setUp() public override {
        super.setUp();

        // premint some amount
        vm.startPrank(users.deployer);
        erc404.mint(users.deployer, 100e18);
    }

    function test_RevertsIf_NotAuthorized() public {
        vm.startPrank(users.stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.stranger));

        erc404.setBaseURI(BASE_URI);
    }

    function test_TokenURIsAreMapped() public {
        uint256 minted = erc404.minted();
        for (uint256 id = 1; id <= minted; id++) {
            uint256 artifactId = uint256(keccak256(abi.encodePacked(id))) % (erc404.totalSupply() / 1e18) + 1;
            string memory expectedURI = string(abi.encodePacked(BASE_URI, artifactId.toString()));
            assertEq(erc404.tokenURI(id), expectedURI);
        }
    }

    function test_IfReset_EmitsBatchMetadataUpdate() public {
        uint256 minted = erc404.minted();

        vm.expectEmit(address(erc404));
        emit ERC404LegacyManagedURI.BatchMetadataUpdate(1, minted);

        erc404.setBaseURI(BASE_URI);
    }
}
