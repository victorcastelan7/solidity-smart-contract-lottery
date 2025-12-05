// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        (uint256 subId,) = createSubscription(vrfCoordinator, account);

        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMT = 3 ether; // 3 link

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinator, subId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken, address account) public {
        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;

        addConsumer(subId, vrfCoordinator, mostRecentlyDeployed, account);
    }

    function addConsumer(uint256 subId, address vrfCoordinator, address mostRecentlyDeployed, address account) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, mostRecentlyDeployed);
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

// contract CreateSubscription is Script {
//     function createSubscriptionUsingConfig() public returns (uint256, address) {
//         HelperConfig helperConfig = new HelperConfig();
//         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//         (uint256 subId,) = createSubscription(vrfCoordinator);

//         return (subId, vrfCoordinator);
//     }

//     function createSubscription(address vrfCoordinator) public returns (uint256, address) {
//         console2.log("Creating subscription on chain id: ", block.chainid);
//         vm.startBroadcast();
//         uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
//         vm.stopBroadcast();

//         console2.log("Your subscription id is: ", subId);
//         console2.log("Please update the subscription Id in your HelperConfig.s.sol");

//         return (subId, vrfCoordinator);
//     }

//     function run() public {
//         createSubscriptionUsingConfig();
//     }
// }

// contract FundSubscription is Script, CodeConstants {
//     uint256 public constant FUND_AMOUNT = 3 ether; // 3 link

//     function fundSubscriptionUsingConfig() public {
//         HelperConfig helperConfig = new HelperConfig();
//         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//         uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
//         address linkToken = helperConfig.getConfig().link;
//         fundSubscription(vrfCoordinator, subscriptionId, linkToken);
//     }

//     function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
//         console2.log("Funding subscription: ", subscriptionId);
//         console2.log("Using vrfcoordinator: ", vrfCoordinator);
//         console2.log("On chainid: ", block.chainid);

//         if (block.chainid == ANVIL_CHAIN_ID) {
//             vm.startBroadcast();
//             VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
//             vm.stopBroadcast();
//         } else {
//             vm.startBroadcast();
//             LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
//             vm.stopBroadcast();
//         }
//     }

//     function run() external {
//         fundSubscriptionUsingConfig();
//     }
//}
