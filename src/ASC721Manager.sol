// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "src/AnimalSocialClubERC721.sol";
import "src/Vera3DistributionModel.sol";

contract ASC721Manager is Ownable, ReentrancyGuard {
    using Strings for uint256;

    // Addresses for funds allocation
    address public adminAddress;
    address public treasuryAddress;

    AnimalSocialClubERC721 public elephant;
    AnimalSocialClubERC721 public tiger;
    AnimalSocialClubERC721 public shark;
    AnimalSocialClubERC721 public eagle;

    AnimalSocialClubERC721[] public contracts;

    constructor(
        address _adminAddress,
        address _treasuryAddress
    ) Ownable(_adminAddress) {
        require(msg.sender == _adminAddress, "sender must be admin");
        require(
            _adminAddress != address(0) && _treasuryAddress != address(0),
            "One or more invalid addresses"
        );
        // Set the beneficiary addresses
        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;

        elephant = new AnimalSocialClubERC721(
            "Animal Social Club Elephant Membership",
            "ASC.Elephant",
            9000,
            0.1 ether,
            address(this),
            treasuryAddress,
            this
        );
        contracts.push(elephant);
        shark = new AnimalSocialClubERC721(
            "Animal Social Club Shark Membership",
            "ASC.Shark",
            520,
            0.5 ether,
            address(this),
            treasuryAddress,
            this
        );
        contracts.push(shark);
        eagle = new AnimalSocialClubERC721(
            "Animal Social Club Eagle Membership",
            "ASC.Eagle",
            200,
            1 ether,
            address(this),
            treasuryAddress,
            this
        );
        contracts.push(eagle);
        tiger = new AnimalSocialClubERC721(
            "Animal Social Club Tiger Membership",
            "ASC.Tiger",
            30,
            2 ether,
            address(this),
            treasuryAddress,
            this
        );
        contracts.push(tiger);
    }

    function isMember(address a) public view returns (bool) {
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            if (tier.balanceOf(a) != 0) {
                return true;
            }
        }
        return false;
    }

    // Function to ensure contract can receive Ether
    receive() external payable {}

    // Function to withdraw funds to respective beneficiaries
    function withdrawFunds() external nonReentrant onlyOwner {
        // console2.log("Hello");
        for (uint i = 0; i < contracts.length; i++) {
            contracts[i].withdrawFunds();
        }

        uint256 balance = address(this).balance;
        // console2.log("got balance");

        if (balance > 0) {
            payable(treasuryAddress).transfer(balance);
        }
    }

    // each of these methods will call the corresponding one on each erc721 contract

    function assignRole(
        address upper,
        Vera3DistributionModel.Role role,
        address delegate
    ) external {
        console.log(
            "ASC721Manager.assignRole msg.sender: ",
            msg.sender,
            " tx.origin: ",
            tx.origin
        );
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            Vera3DistributionModel(tier).assignRole(upper, role, delegate);
        }
    }

    function setAmbassadorToAdvocateCommission(
        address delegate,
        uint percentage
    ) external {
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            Vera3DistributionModel(tier).setAmbassadorToAdvocateCommission(
                delegate,
                percentage
            );
        }
    }

    function setAdvocateToEvangelistCommission(
        address delegate,
        uint percentage
    ) external {
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            Vera3DistributionModel(tier).setAdvocateToEvangelistCommission(
                delegate,
                percentage
            );
        }
    }

    function setSaleActive(bool isSaleActive) external {
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            tier.setSaleActive(isSaleActive);
        }
    }
}
