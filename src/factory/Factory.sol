// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC404ManagedURI } from "src/extensions/ERC404ManagedURI.sol";
import { IFactory } from "./IFactory.sol";

contract Factory is IFactory, Ownable {
    address public immutable vault;
    uint256 public deploymentFee;
    mapping(address deployer => address[] deployments) internal _deploymentsOf;

    constructor(address vault_, uint256 deploymentFee_, address admin_) Ownable(admin_) {
        vault = vault_;
        deploymentFee = deploymentFee_;
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
        if (msg.value != deploymentFee) revert InsufficientDeploymentFee();

        ERC404ManagedURI erc404 = new ERC404ManagedURI(name, symbol, baseURI, totalNFTSupply, msg.sender);
        _deploymentsOf[msg.sender].push(address(erc404));

        emit ERC404Deployed(msg.sender, address(erc404));
        if (msg.value > 0) {
            payable(vault).transfer(msg.value);
        }

        return address(erc404);
    }

    function setDeploymentFee(uint256 newDeploymentFee) external onlyOwner {
        emit DeploymentFeeChanged(deploymentFee, newDeploymentFee);

        deploymentFee = newDeploymentFee;
    }

    function deploymentsOf(address owner) external view returns (address[] memory) {
        return _deploymentsOf[owner];
    }
}
