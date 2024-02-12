// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC404ManagedURI } from "src/extensions/ERC404ManagedURI.sol";
import { IFactory } from "./IFactory.sol";

contract Factory is IFactory, Ownable {
    address public immutable vault;
    uint256 public deploymentFee;
    uint256 public deploymentCounter; 
    uint256 public totalFeesEarned;
    uint256 public freeDeploymentLimit;

    mapping(address deployer => address[] deployments) internal _deploymentsOf;

    constructor(address vault_, uint256 deploymentFee_, address admin_, uint256 freeDeploymentLimit_,) Ownable(admin_) {
        vault = vault_;
        deploymentFee = deploymentFee_;
        freeDeploymentLimit = freeDeploymentLimit_;
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
        if (deploymentCounter >= freeDeploymentLimit && msg.value != deploymentFee) revert InsufficientDeploymentFee();

        ERC404ManagedURI erc404 = new ERC404ManagedURI(name, symbol, baseURI, totalNFTSupply, msg.sender);
        _deploymentsOf[msg.sender].push(address(erc404));

        if (deploymentCounter > freeDeploymentLimit) {
            totalFeesEarned += msg.value; 
            payable(vault).transfer(msg.value); 
        }

        deploymentCounter++; 

        emit ERC404Deployed(msg.sender, address(erc404));
        return address(erc404);
    }

    function setDeploymentFee(uint256 newDeploymentFee) external onlyOwner {
        emit DeploymentFeeChanged(deploymentFee, newDeploymentFee);
        deploymentFee = newDeploymentFee;
    }

    function setFreeDeploymentLimit(uint256 newFreeDeploymentLimit) external onlyOwner {
        freeDeploymentLimit = newFreeDeploymentLimit;
    }

    function deploymentsOf(address owner) external view returns (address[] memory) {
        return _deploymentsOf[owner];
    }

    function getDeploymentCount() external view returns (uint256) {
        return deploymentCounter;
    }

    function getTotalFeesEarned() external view returns (uint256) {
        return totalFeesEarned;
    }
}
