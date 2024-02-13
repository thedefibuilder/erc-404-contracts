// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC404ManagedURI } from "src/extensions/ERC404ManagedURI.sol";

contract Factory is Ownable {
    error InsufficientDeploymentFee();
    error StartTimeTooBig();
    error EndTimeTooSmall();

    event FreePeriodChanged(FreePeriod newFreePeriod);
    event DeploymentFeeChanged(uint128 oldDeploymentFee, uint128 newDeploymentFee);
    event ERC404Deployed(address indexed deployer, address indexed erc404);

    struct FreePeriod {
        uint64 start;
        uint64 end;
    }

    /// @notice The address that will receive the deployment fees.
    address public immutable vault;

    // ----------------------- Internals -----------------------
    FreePeriod internal _freePeriod;
    uint128 internal _deploymentFee;
    mapping(address deployer => address[] deployments) internal _deploymentsOf;

    constructor(
        address vault_,
        uint128 deploymentFee_,
        address admin_,
        FreePeriod memory freePeriod_
    )
        Ownable(admin_)
    {
        vault = vault_;
        _deploymentFee = deploymentFee_;
        _setFreePeriod(freePeriod_);
    }

    function deployERC404(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 totalNFTSupply
    )
        external
        payable
        returns (address)
    {
        if (msg.value != deploymentFee()) revert InsufficientDeploymentFee();

        ERC404ManagedURI erc404 = new ERC404ManagedURI(name, symbol, baseURI, totalNFTSupply, msg.sender);
        _deploymentsOf[msg.sender].push(address(erc404));

        emit ERC404Deployed(msg.sender, address(erc404));
        if (msg.value > 0) {
            payable(vault).transfer(msg.value);
        }

        return address(erc404);
    }

    /// @notice Set the fee required to deploy a new contract.
    function setDeploymentFee(uint128 newDeploymentFee) external onlyOwner {
        emit DeploymentFeeChanged(_deploymentFee, newDeploymentFee);

        _deploymentFee = newDeploymentFee;
    }

    /// @notice Set the period during which deployments are free.
    function setFreePeriod(FreePeriod memory newFreePeriod) external onlyOwner {
        _setFreePeriod(newFreePeriod);
    }

    /// @notice The period during which deployments are free.
    function freePeriod() external view returns (FreePeriod memory) {
        return _freePeriod;
    }

    /// @notice The fee required to deploy a new contract.
    /// @dev The fee is 0 during the free period.
    function deploymentFee() public view returns (uint128) {
        if (_freePeriod.start <= block.timestamp && block.timestamp < _freePeriod.end) {
            return 0;
        }
        return _deploymentFee;
    }

    /// @notice Get all the contracts deployed by an user.
    function deploymentsOf(address owner) external view returns (address[] memory) {
        return _deploymentsOf[owner];
    }

    function _setFreePeriod(FreePeriod memory newFreePeriod) internal {
        // End = 0 means the free period is disabled.
        if (newFreePeriod.end > 0) {
            if (newFreePeriod.start > newFreePeriod.end) revert StartTimeTooBig();
            if (newFreePeriod.end < block.timestamp) revert EndTimeTooSmall();
        }
        _freePeriod = newFreePeriod;
        emit FreePeriodChanged(newFreePeriod);
    }
}
