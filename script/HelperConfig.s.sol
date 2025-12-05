// SPDX-License-Identifier: MIT

// sepolia
// entranceFee: 0.1 ether,
// interval: 30,
// vrfCoordinator: address(0),
// gasLane: 0,
// subscriptionId: 0,
// callBackGasLimit: 50000

// uint256 entranceFee;
// uint256 interval;
// address vrfCoordinator;
// bytes32 gasLane;
// uint32 callBackGasLimit;
// uint256 subscriptionId;

pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public SEPOLIA_CHAIN_ID = 11155111;
    uint256 public ANVIL_CHAIN_ID = 31337;
    uint96 public BASE_FEE = 0.25 ether;
    uint96 public GAS_PRICE = 1e9;
    int256 public WEI_PER_UNIT_LINK = 4e15;
    uint256 public constant FUND_AMOUNT = 100 ether;
}

contract HelperConfig is Script, CodeConstants {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    error HelperConfig__InvalidChainId();

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAIN_ID) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x474e34a077df29f1c5f3c74f5e5f159e9369e5e790f74b1f00b9f6f4f5f5972a,
            subscriptionId: 95103547707007248069826624750827188107857680031146283789214661362219547111801,
            callbackGasLimit: 250000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xff8DB87863c98b8bA9d4D8c01e3F91d489E64520
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        VRFCoordinatorV2_5Mock mockCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        activeNetworkConfig = NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: address(mockCoordinator),
            gasLane: 0,
            subscriptionId: 0,
            callbackGasLimit: 250000,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // default sender address from base.sol
        });

        return activeNetworkConfig;
    }
}

