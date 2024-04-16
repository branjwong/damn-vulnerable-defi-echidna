// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../src/DamnValuableTokenSnapshot.sol";
import "../src/SimpleGovernance.sol";
import "../src/SelfiePool.sol";

contract ProofsOfConcept is Test {
    address _attacker = makeAddr("attacker");

    Deployer _deployer;

    ERC20Snapshot private _token;
    SimpleGovernance private _gov;
    SelfiePool private _pool;

    constructor() {
        _deployer = new Deployer();
        (_token, _gov, _pool) = _deployer.deploy();
    }

    function testHappyPath() external {
        LoanUser loanUser = new LoanUser(_token, _pool);
        loanUser.act();
    }

    function testAttack() external {
        uint256 tokensInPool = _deployer.TOKENS_IN_POOL();

        assertEq(_token.balanceOf(_attacker), 0);
        assertEq(_token.balanceOf(address(_pool)), tokensInPool);

        vm.startPrank(_attacker);
        Attack attack = new Attack();
        attack.attack(tokensInPool);

        assertEq(_token.balanceOf(_attacker), tokensInPool);
        assertEq(_token.balanceOf(address(_pool)), 0);
    }
}

contract Deployer {
    uint256 public immutable INITIAL_SUPPLY = 2000000;
    uint256 public immutable TOKENS_IN_POOL = 1500000;

    function deploy()
        external
        returns (ERC20Snapshot token, SimpleGovernance gov, SelfiePool pool)
    {
        token = new DamnValuableTokenSnapshot(INITIAL_SUPPLY);

        gov = new SimpleGovernance(address(token));
        pool = new SelfiePool(address(token), address(gov));

        token.transfer(address(pool), TOKENS_IN_POOL);
    }
}

contract LoanUser {
    ERC20Snapshot _token;
    SelfiePool _pool;

    constructor(ERC20Snapshot token, SelfiePool pool) {
        _token = token;
        _pool = pool;
    }

    function act() external {
        console.log("Current balance: %d", _token.balanceOf(address(this)));
        _pool.flashLoan(100);
    }

    function receiveTokens(address token, uint256 amount) external {
        console.log("Received flash loan: %d", amount);
        console.log(
            "Current balance: %d",
            ERC20Snapshot(token).balanceOf(address(this))
        );

        ERC20Snapshot(token).transfer(address(_pool), amount);
        console.log("Returned loan of %d", amount);

        console.log(
            "Current balance: %d",
            ERC20Snapshot(token).balanceOf(address(this))
        );
    }
}

contract Attack {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function attack(uint256 amount) external {
        require(msg.sender == _owner, "Only _owner can call");

        // get loan
        // use loan to queue drain funds
        // return funds
        // drain funds
    }
}
