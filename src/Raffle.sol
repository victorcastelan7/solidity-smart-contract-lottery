// SPDX-License-Identifier: MIT

// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    address payable[] private s_raffleEntrants;
    uint256 private s_lastTimestamp = block.timestamp;
    uint256 private immutable i_interval;
    uint256 private immutable i_raffleFee;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;
    RaffleState private s_raffleState = RaffleState.OPEN;

    event RaffleEntered(address indexed player);
    event RecentWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    error Raffle__EntranceFeeNotMet();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded();
    error Raffle__TransactionFailed();


    constructor(
        uint256 raffleFee,
        uint256 interval,
        address VRFCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(VRFCoordinator) {
        i_raffleFee = raffleFee;
        i_interval = interval;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    function enterRaffle() external payable {
        if (msg.value < i_raffleFee) revert Raffle__EntranceFeeNotMet();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        s_raffleEntrants.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool hasPlayers = s_raffleEntrants.length > 0;
        bool isRaffleOpen = s_raffleState == RaffleState.OPEN;
        bool enoughTimePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        bool contractHasBalance = address(this).balance > 0;

        upkeepNeeded = (hasPlayers && isRaffleOpen && enoughTimePassed && contractHasBalance);

        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) revert Raffle__UpkeepNotNeeded();

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_raffleEntrants.length;
        address payable winner = s_raffleEntrants[indexOfWinner];

        s_raffleState = RaffleState.OPEN;

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransactionFailed();

        s_recentWinner = winner;
        s_lastTimestamp = block.timestamp;
        s_raffleEntrants = new address payable[](0);
        emit RecentWinner(winner);
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumberOfEntrants() public view returns (uint256) {
        return s_raffleEntrants.length;
    }

    function getLastTimeStamp() public view returns (uint256) {
      return s_lastTimestamp;
    }

    function getRecentWinner() public view returns (address) {
      return s_recentWinner;
    }
}

