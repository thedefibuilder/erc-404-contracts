// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.23;

interface IProxyFactory {
    error InsufficientDeploymentFee();

    /// @notice Deploy a new upgradeable proxy.
    function deployUpgradeableProxy(bytes calldata initData) external payable returns (address);

    /// @notice Get all the proxies deployed by an address.
    function getDeployedProxies(address owner) external view returns (address[] memory);

    /// @notice Set the fee required to deploy a new proxy.
    function setDeploymentFee(uint256 newDeploymentFee) external;

    /// @notice The fee required to deploy a new proxy.
    function deploymentFee() external view returns (uint256);

    /// @notice The address that will receive the deployment fees.
    function vault() external view returns (address);
}
