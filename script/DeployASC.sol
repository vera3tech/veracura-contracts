// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "src/AnimalSocialClubERC721.sol";
import "src/Vera3DistributionModel.sol";

import {Script, console} from "forge-std/Script.sol";
import {ASC721Manager} from "../src/ASC721Manager.sol";

contract DeployASC is Script {
    ASC721Manager public asc;
    address payable public asc_address;
    address public constant ADMIN_ADDRESS =
        0x98A5c7E6eb3DEaf7Db34d14d63D46ec5a5A2f775; // dummy CHANGE THIS FOR MAINNET
    address public constant TREASURY_ADDRESS =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // dummy CHANGE THIS FOR MAINNET

    address public constant ETH_FEE_PROXY_ADDRESS =
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // base sepolia
    address public constant LINK_ADDRESS =
        0xE4aB69C077896252FAFBD49EFD26B5D171A32410; // base sepolia
    address public constant VRF_WRAPPER_ADDRESS =
        0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; // base sepolia

    address public constant DUMMY_WAITLISTED_ADDRESS =
        address(0xe198f322E463510deB487170dD299Df9787f5470);

    uint256 public constant ELEPHANT_ID = 0;
    uint256 public constant TIGER_ID = 1;
    uint256 public constant SHARK_ID = 2;
    uint256 public constant EAGLE_ID = 3;
    uint256 public constant STAKEHOLDER_ID = 4;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        ASCLottery lottery = new ASCLottery(
            LINK_ADDRESS,
            VRF_WRAPPER_ADDRESS,
            TREASURY_ADDRESS
        );
        asc_address = payable(
            Upgrades.deployUUPSProxy(
                "ASC721Manager.sol",
                abi.encodeCall(
                    ASC721Manager.initialize,
                    (TREASURY_ADDRESS, address(lottery))
                )
            )
        );
        asc = ASC721Manager(asc_address);
        lottery.transferOwnership(asc_address);

        address elephantAddress = Upgrades.deployUUPSProxy(
            "AnimalSocialClubERC721.sol",
            abi.encodeCall(
                AnimalSocialClubERC721.initialize,
                (
                    "Animal Social Club Elephant Membership",
                    "ASC.Elephant",
                    9000,
                    0.1 ether,
                    ADMIN_ADDRESS,
                    TREASURY_ADDRESS,
                    asc,
                    0,
                    ETH_FEE_PROXY_ADDRESS,
                    ELEPHANT_ID
                )
            )
        );
        address sharkAddress = Upgrades.deployUUPSProxy(
            "AnimalSocialClubERC721.sol",
            abi.encodeCall(
                AnimalSocialClubERC721.initialize,
                (
                    "Animal Social Club Shark Membership",
                    "ASC.Shark",
                    520,
                    0.5 ether,
                    ADMIN_ADDRESS,
                    TREASURY_ADDRESS,
                    asc,
                    0,
                    ETH_FEE_PROXY_ADDRESS,
                    SHARK_ID
                )
            )
        );

        address eagle = Upgrades.deployUUPSProxy(
            "AnimalSocialClubERC721.sol",
            abi.encodeCall(
                AnimalSocialClubERC721.initialize,
                (
                    "Animal Social Club Eagle Membership",
                    "ASC.Eagle",
                    200,
                    1 ether,
                    ADMIN_ADDRESS,
                    TREASURY_ADDRESS,
                    asc,
                    9, // 9 eagle reserved for lottery
                    ETH_FEE_PROXY_ADDRESS,
                    EAGLE_ID
                )
            )
        );

        address tiger = Upgrades.deployUUPSProxy(
            "AnimalSocialClubERC721.sol",
            abi.encodeCall(
                AnimalSocialClubERC721.initialize,
                (
                    "Animal Social Club Tiger Membership",
                    "ASC.Tiger",
                    30,
                    2 ether,
                    ADMIN_ADDRESS,
                    TREASURY_ADDRESS,
                    asc,
                    11, // 1 tiger reserved for lottery, 10 tigers in auction
                    ETH_FEE_PROXY_ADDRESS,
                    TIGER_ID
                )
            )
        );
        address stakeholder = Upgrades.deployUUPSProxy(
            "AnimalSocialClubERC721.sol",
            abi.encodeCall(
                AnimalSocialClubERC721.initialize,
                (
                    "Animal Social Club Stakeholder Membership",
                    "ASC.Stakeholder",
                    250,
                    0.5 ether,
                    ADMIN_ADDRESS,
                    TREASURY_ADDRESS,
                    asc,
                    0,
                    ETH_FEE_PROXY_ADDRESS,
                    STAKEHOLDER_ID
                )
            )
        );

        asc.assignContracts(
            payable(elephantAddress),
            payable(tiger),
            payable(sharkAddress),
            payable(eagle),
            payable(stakeholder)
        );

        require(asc.owner() == address(ADMIN_ADDRESS));
        AnimalSocialClubERC721[5] memory contracts = [
            AnimalSocialClubERC721(payable(elephantAddress)),
            AnimalSocialClubERC721(payable(tiger)),
            AnimalSocialClubERC721(payable(sharkAddress)),
            AnimalSocialClubERC721(payable(eagle)),
            AnimalSocialClubERC721(payable(stakeholder))
        ];
        for (uint i = 0; i < contracts.length; i++) {
            require(contracts[i].owner() == address(ADMIN_ADDRESS));
        }

        asc.addToWaitlist(
            TIGER_ID,
            asc.tiger().PRICE() / 50,
            DUMMY_WAITLISTED_ADDRESS
        );

        vm.stopBroadcast();

        console.log("Done. Animal Social Club Manager address: ", asc_address);
    }
}
