// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // CREATE SUB

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);
        }

        // FUND SUB
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.callbackGasLimit,
            config.subscriptionId
        );
        vm.stopBroadcast();

        // ADD CONSUMER
        AddConsumer addConsumer = new AddConsumer();
       addConsumer.addConsumer(config.subscriptionId, config.vrfCoordinator, address(raffle), config.account );

           return (raffle, helperConfig);
    }


}



















// import {Script} from "forge-std/Script.sol";
// import {Raffle} from "src/Raffle.sol";
// import {HelperConfig} from "./HelperConfig.s.sol";
// import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

// contract DeployRaffle is Script {
//     function run() public {}

//     function deployContract() public returns (Raffle, HelperConfig) {
//         HelperConfig helperConfig = new HelperConfig();
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         // CREATE SUB
//         if (config.subscriptionId == 0) {
//             CreateSubscription createSubscription = new CreateSubscription();
//             (config.subscriptionId, config.vrfCoordinator) =
//                 createSubscription.createSubscription(config.vrfCoordinator);

//         // FUND SUB
//             FundSubscription fundSubscription = new FundSubscription();
//             fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
//         }

//         // CREATE CONTRACT "CONSUMER"
//         vm.startBroadcast();
//         Raffle raffle = new Raffle(
//             config.entranceFee,
//             config.interval,
//             config.vrfCoordinator,
//             config.gasLane,
//             config.callbackGasLimit,
//             config.subscriptionId
//         );
//         vm.stopBroadcast();

//         // ADD CONSUMER
//         AddConsumer addConsumer = new AddConsumer();
//         addConsumer.addConsumer(config.subscriptionId, config.vrfCoordinator, address(raffle));

//         return (raffle, helperConfig);
//     }
// }

