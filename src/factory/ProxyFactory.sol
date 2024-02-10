// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.23;

import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IProxyFactory } from "./IProxyFactory.sol";

contract ProxyFactory is IProxyFactory, IBeacon, Ownable {
    address public override vault;
    address public implementation;
    uint256 public override deploymentFee;

    mapping(address deployer => address[] proxies) internal _deployedProxies;

    constructor(address vault_, uint256 deploymentFee_, address implementation_, address admin_) Ownable(admin_) {
        vault = vault_;
        deploymentFee = deploymentFee_;
        implementation = implementation_;
    }

    function deployUpgradeableProxy(bytes calldata initData) external payable returns (address) {
        if (msg.value != deploymentFee) revert InsufficientDeploymentFee();

        BeaconProxy proxy = new BeaconProxy(address(this), initData);
        _deployedProxies[msg.sender].push(address(proxy));

        payable(vault).transfer(msg.value);

        return address(proxy);
    }

    function setDeploymentFee(uint256 newDeploymentFee) external onlyOwner {
        deploymentFee = newDeploymentFee;
    }

    function getDeployedProxies(address owner) external view returns (address[] memory) {
        return _deployedProxies[owner];
    }
}
