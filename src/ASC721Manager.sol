// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "src/AnimalSocialClubERC721.sol";
import "src/Vera3DistributionModel.sol";

contract ASC721Manager is AccessControl, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    error CallerNotAdmin(address caller);
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    error CallerNotOperator(address caller);

    // Addresses for funds allocation
    address public immutable adminAddress;
    address public immutable treasuryAddress;

    AnimalSocialClubERC721 public immutable elephant;
    AnimalSocialClubERC721 public immutable tiger;
    AnimalSocialClubERC721 public immutable shark;
    AnimalSocialClubERC721 public immutable eagle;

    mapping(address => bool) private _hasKYC;

    AnimalSocialClubERC721[] public contracts;

    constructor(
        address _adminAddress,
        address _treasuryAddress
    ) AccessControl() {
        require(msg.sender == _adminAddress, "sender must be admin");
        require(
            _adminAddress != address(0) && _treasuryAddress != address(0),
            "One or more invalid addresses"
        );

        require(
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "could not grant role"
        );
        require(_grantRole(OPERATOR_ROLE, msg.sender), "could not grant role");
        require(_grantRole(ADMIN_ROLE, msg.sender), "could not grant role");

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

    function setOperator(address a) public onlyRole(ADMIN_ROLE) {
        require(_grantRole(OPERATOR_ROLE, a), "role not granted");
    }

    function hasKYC(address a) public view returns (bool) {
        return _hasKYC[a];
    }

    function setKYC(address a, bool val) public onlyRole(OPERATOR_ROLE) {
        _hasKYC[a] = val;
    }

    function isMember(address a) public view returns (bool) {
        uint len = contracts.length; // gas optimization
        for (uint i = 0; i < len; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            // slither-disable-next-line calls-loop
            if (tier.balanceOf(a) != 0) {
                return true;
            }
        }
        return false;
    }

    // Function to ensure contract can receive Ether
    receive() external payable {}

    // Function to withdraw funds to respective beneficiaries
    function withdrawFunds() external nonReentrant onlyRole(ADMIN_ROLE) {
        // console2.log("Hello");
        for (uint i = 0; i < contracts.length; i++) {
            // slither-disable-next-line calls-loop
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
            // slither-disable-next-line calls-loop
            Vera3DistributionModel(tier).assignRole(upper, role, delegate);
        }
    }

    function setAmbassadorToAdvocateCommission(
        address delegate,
        uint percentage
    ) external {
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            // slither-disable-next-line calls-loop
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
            // slither-disable-next-line calls-loop
            Vera3DistributionModel(tier).setAdvocateToEvangelistCommission(
                delegate,
                percentage
            );
        }
    }

    function setSaleActive(bool isSaleActive) external {
        for (uint i = 0; i < contracts.length; i++) {
            AnimalSocialClubERC721 tier = contracts[i];
            // slither-disable-next-line calls-loop
            tier.setSaleActive(isSaleActive);
        }
    }
}
