// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@common/uniswap/UniswapV1Exchange.sol";
import "@common/DamnValuableToken.sol";

import "../src/PuppetPool.sol";
import "./Deployer.sol";

contract ProofsOfConcept is Test {
    address _attacker = makeAddr("attacker");

    Deployer _deployer;

    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    constructor() {
        _deployer = new Deployer();
        (_token, _pool, _exchange) = _deployer.deploy{value: 10 ether}();
    }

    function testHappyPath() external {
        assertEq(
            _exchange.getTokenToEthInputPrice(1 ether),
            calculateTokenToEthInputPrice(1 ether, 10 ether, 10 ether)
        );

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

    // Calculates how much ETH (in wei) Uniswap will pay for the given amount of tokens
    function calculateTokenToEthInputPrice(
        uint256 tokensSold,
        uint256 tokensInReserve,
        uint256 etherInReserve
    ) internal pure returns (uint256) {
        return
            (tokensSold * 997 * etherInReserve) /
            (tokensInReserve * 1000 + tokensSold * 997);
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
