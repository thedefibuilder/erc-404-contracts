// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
    address internal broadcaster;

    struct ChainConfig {
        address admin;
        uint256 chainId;
        uint256 deploymentFee;
        address legacyFactory;
        address templateFactory;
        address vault;
    }

    ChainConfig public config;

    function setUp() public virtual {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        broadcaster = vm.rememberKey(privateKey);

        string memory json = vm.readFile("script/config.json");
        ChainConfig[] memory configs = abi.decode(vm.parseJson(json), (ChainConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            if (block.chainid == configs[i].chainId) {
                config = configs[i];
                break;
            }
        }

        // solhint-disable-next-line custom-errors
        require(config.chainId != 0, "Chain config not found");
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }
}
