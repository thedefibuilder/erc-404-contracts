// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Deployments } from "script/DeploymentsLib.sol";
import { ERC404ManagedURI } from "src/templates/ERC404ManagedURI.sol";
import { toTemplate, TemplateType, Template } from "src/types/Template.sol";
import { TemplateFactoryTest } from "test/template/factory/TemplateFactory.t.sol";

abstract contract ERC404ManagedURITest is TemplateFactoryTest {
    ERC404ManagedURI public erc404;

    string public constant NAME = "name";
    string public constant SYMBOL = "symbol";
    string public constant BASE_URI = "https://example.com/";
    uint256 public constant TOTAL_NFT_SUPPLY = 10_000;

    function setUp() public virtual override {
        super.setUp();

        address erc404CodePointer = Deployments.deployCodePointer(type(ERC404ManagedURI).creationCode);
        bytes32 erc404TemplateId = bytes32(uint256(1));

        Template erc404Template = toTemplate(erc404CodePointer, TemplateType.SimpleContract, 0);

        vm.startPrank(users.admin);
        factory.setTemplate(erc404TemplateId, erc404Template);
        erc404 = ERC404ManagedURI(
            factory.deployTemplate(
                erc404TemplateId, abi.encode(NAME, SYMBOL, BASE_URI, TOTAL_NFT_SUPPLY, users.deployer)
            )
        );
    }
}
