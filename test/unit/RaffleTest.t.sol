// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 100 ether;

    event RaffleEntered(address indexed player);
    event RecentWinner(address indexed winner);


    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, 100 ether);
    }

    function testRaffleInitializesInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRevertOnInsuffiecientEntranceFee() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__EntranceFeeNotMet.selector);
        raffle.enterRaffle();
    }

    function testPlayersGetAddedToRaffle() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();
        assert(raffle.getNumberOfEntrants() == 1);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        raffle.enterRaffle{value: 0.1 ether}();
    }

    function testDenyEntryWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();
    }


    ///////////////////// Check upkeep //////////////////////

    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    // testCheckUpkeepReturnsFalseIfTimeHasNotPassed
    function testCheckUpkeepReturnsFalseIfTimeHasNotPassed() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();

      (bool upkeepNeeded, ) = raffle.checkUpkeep("");

      assert(!upkeepNeeded);
    }

    // testCheckUpkeepReturnsTrueWhenParametersAreGood
    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();

      vm.warp(block.timestamp + interval + 1);
      vm.roll(block.number + 1);

      (bool upkeepNeeded, ) = raffle.checkUpkeep("");

      assert(upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepReturnsTrue() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();

      vm.warp(block.timestamp + interval + 1);
      vm.roll(block.number + 1);

      raffle.performUpkeep("");

    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
      uint256 currentBalance = 0;
      uint256 numPlayers = 0;
      Raffle.RaffleState rState = raffle.getRaffleState();

      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();

      currentBalance = 1 ether;
      numPlayers = 1;

      
      vm.expectRevert(
        abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
      );

      raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();

      vm.warp(block.timestamp + interval + 1);
      vm.roll(block.number + 1);

      vm.recordLogs();
      raffle.performUpkeep("");

      Vm.Log[] memory entries = vm.getRecordedLogs();
      bytes32 requestId = entries[1].topics[1];

      Raffle.RaffleState raffleState = raffle.getRaffleState();
      assert(uint256(requestId) > 0);
      assert(uint256(raffleState) == 1);

    }

    /////////////////////Fullfill Random WOrds //////////////////////

    modifier skipFork() {
      if (block.chainid != ANVIL_CHAIN_ID) {
        return;
      }
      _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public skipFork {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();

      console2.log("vrfCoordinator in test:", vrfCoordinator);
      console2.log("code length:", vrfCoordinator.code.length);

      vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
      VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerAndResetsAndSendsMoney() public skipFork {
      console2.log("chainid is", block.chainid);
      console2.log("player has", PLAYER.balance);
      console2.log("raffle has", address(this).balance);
      // Arrange
      vm.prank(PLAYER);
      raffle.enterRaffle{value: 1 ether}();
      vm.warp(block.timestamp + interval + 1);
      vm.roll(block.number + 1);
      console2.log("raffle has", address(this).balance);

      uint256 additionalEntrants = 3; // 4 People total
      uint256 startingIndex = 1;
      address expectedWinner = address(1);

      for(uint256 i = 1; i < startingIndex + additionalEntrants; i++) {
        address newPlayer = address(uint160(i));
        hoax(newPlayer, 1 ether);
        raffle.enterRaffle{value: 1 ether}();
      }

      uint256 startingTimeStamp = raffle.getLastTimeStamp();
      uint256 winnerStartingBalance = expectedWinner.balance;

      // Act
      vm.recordLogs();
      raffle.performUpkeep("");

      Vm.Log[] memory entries = vm.getRecordedLogs();
      bytes32 requestId = entries[1].topics[1];
      VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

      address recentWinner = raffle.getRecentWinner();
      Raffle.RaffleState raffleState = raffle.getRaffleState();
      uint256 winnerBalance = recentWinner.balance;
      uint256 endingTimeStamp = raffle.getLastTimeStamp();
      uint256 prize = (additionalEntrants + 1) * 1 ether;

      // Assert
      assert(recentWinner == expectedWinner);
      assert(uint256(raffleState) == 0);
      assert(winnerBalance == winnerStartingBalance + prize);
      assert(endingTimeStamp > startingTimeStamp);
    }

}
