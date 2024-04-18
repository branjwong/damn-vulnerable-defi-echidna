// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@common/DamnValuableToken.sol";

import "../src/PuppetPool.sol";
import "./Deployer.sol";

contract ProofsOfConcept is Test {
    address _attacker = makeAddr("attacker");

    Deployer _deployer;
    DamnValuableToken _token;
    PuppetPool _pool;

    constructor() {
        _deployer = new Deployer();
    }

    function testHappyPath() external {
        LoanUser loanUser = new LoanUser();
        vm.deal(address(loanUser), 1000 ether);

        loanUser.act();
    }

    function testAttack() external {
        // Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.
        vm.deal(_attacker, 25 ether);
        deal(address(_token), _attacker, 1000);

        uint256 poolTokens = _deployer.POOL_TOKENS();

        assertEq(_token.balanceOf(address(_attacker)), 1000);
        assertEq(_token.balanceOf(address(_pool)), poolTokens);

        vm.startPrank(_attacker);
        Attack attack = new Attack(_pool);
        attack.attack(poolTokens);

        assertEq(_token.balanceOf(address(_attacker)), 1000 + poolTokens);
        assertEq(_token.balanceOf(address(_pool)), 0);
    }
}

contract LoanUser {
    function act() external {}

    receive() external payable {}
}

contract Attack {
    PuppetPool _pool;

    constructor(PuppetPool pool) {
        _pool = pool;
    }

    function attack(uint256 amount) external {}
}
