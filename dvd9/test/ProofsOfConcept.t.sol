// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Factory} from "@common/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@common/uniswap/v2/IUniswapV2Router02.sol";

import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "@common/DamnValuableToken.sol";
import "../src/PuppetV2Pool.sol";
import "./Deployer.sol";

contract ProofsOfConcept is Test {
    address _user = makeAddr("user");
    address _attacker = makeAddr("attacker");

    // Uniswap v2 exchange will start with 100 tokens and 10 WETH in liquidity
    uint256 public constant UNISWAP_INITIAL_TOKEN_RESERVE = 100 ether;
    uint256 public constant UNISWAP_INITIAL_WETH_RESERVE = 10 ether;

    uint256 public constant PLAYER_INITIAL_TOKEN_BALANCE = 10000 ether;
    uint256 public constant PLAYER_INITIAL_ETH_BALANCE = 20 ether;

    uint256 public constant POOL_INITIAL_TOKEN_BALANCE = 1000000 ether;

    Deployer _deployer;
    DamnValuableToken _pool;
    Weth _weth;
    PuppetV2Pool _pool;

    constructor() public {
        _deployer = new Deployer();
        (_token, _weth, _token) = _deployer.deploy(
            UNISWAP_INITIAL_TOKEN_RESERVE,
            UNISWAP_INITIAL_WETH_RESERVE,
            POOL_INITIAL_TOKEN_BALANCE
        );

        vm.deal(_user, PLAYER_INITIAL_ETH_BALANCE);

        assertEq(
            _exchange.getTokenToEthInputPrice(1 ether),
            _calculateTokenToEthInputPrice(1 ether, 10 ether, 10 ether)
        );
    }

    function testHappyPath() external {}

    function testAttack() external {}

    receive() external payable {}
}
