// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.23;

interface IFactory {
    error InsufficientDeploymentFee();

    function deployERC404(
        string memory name,
        string memory symbol,
        uint256 totalNFTSupply
    )
        external
        payable
        returns (address);

    /// @notice Set the fee required to deploy a new proxy.
    function setDeploymentFee(uint256 newDeploymentFee) external;

    /// @notice Get all the proxies deployed by an address.
    function deploymentsOf(address owner) external view returns (address[] memory);

    /// @notice The fee required to deploy a new proxy.
    function deploymentFee() external view returns (uint256);

    /// @notice The address that will receive the deployment fees.
    function vault() external view returns (address);
}
