// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
    address internal broadcaster;

    struct ChainConfig {
        uint256 deploymentFee;
        address vault;
        address admin;
    }

    mapping(uint256 chainId => ChainConfig config) public chainConfigs;
    ChainConfig public currentChainConfig;

    function setUp() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        broadcaster = vm.rememberKey(privateKey);
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }
}
