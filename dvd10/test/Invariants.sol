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
        UnsolvedSomething,
        UnorderedFunctions,
        NoHarness
    }

    error OnlyTestingLevel(TestingLevel supported);

    TestingLevel private _testingLevel = TestingLevel.UnorderedFunctions;

    Deployer _deployer;

    DamnValuableToken _token;

    constructor() payable {
        _deployer = new Deployer();
        (_token) = _deployer.deploy();
    }

    modifier onlyTestingLevel(TestingLevel testingLevel) {
        if (_testingLevel != testingLevel) {
            revert OnlyTestingLevel(testingLevel);
        }

        _;
    }

    // //////////////// //
    // EDUCATED GUESSES //
    // //////////////// //

    function attack() public onlyTestingLevel(TestingLevel.Solved) {
        _attack();
    }

    function attackWithSomething()
        external
        onlyTestingLevel(TestingLevel.UnsolvedSomething)
    {
        _attack();
    }

    function attackWithTokenValues(
        uint256 tokenToEthAmount,
        uint256 poolBorrowAmount
    ) external onlyTestingLevel(TestingLevel.UnsolvedTokenValues) {
        _attack();
    }

    // ///////////////// //
    // PRIVATE FUNCTIONS //
    // ///////////////// //

    function _attack() internal {
        // ...
    }

    // @audit-info if can't get educated guess to work, try implementing it in an invariant property, getting it to pass.
    function disabled_echidna_test_attack_doesnt_revert()
        internal
        returns (bool)
    {
        attack();
        return true;
    }

    // /////////////////// //
    // UNORDERED FUNCTIONS //
    // /////////////////// //

    // ...

    // //////////////////// //
    // INVARIANT PROPERTIES //
    // //////////////////// //

    function echidna_cannot_empty_tokens_from_pool()
        public
        view
        returns (bool)
    {
        return _token.balanceOf(address(_pool)) > 0;
    }

    // @audit-info if receive is missing, educated guess will fail
    receive() external payable {}
}
