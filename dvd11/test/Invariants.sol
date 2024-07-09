pragma solidity ^0.8.0;

import "@common/DamnValuableToken.sol";

import "../src/WalletRegistry.sol";
import "./Deployer.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna test/Invariants.sol --contract Echidna --config test/echidna.config.yaml
///      ```
contract Echidna {
    // Determines how fast Echidna can find the solution
    enum TestingLevel {
        // < 200 calls: 1 sec
        Solved,
        UnsolvedSomething,
        UnorderedFunctions,
        NoHarness
    }

    error OnlyTestingLevel(TestingLevel supported);

    TestingLevel private _testingLevel = TestingLevel.NoHarness;

    Deployer _deployer;

    DamnValuableToken _token;
    GnosisSafeProxyFactory _walletFactory;
    WalletRegistry _registry;
    address[] _users = new address[](4);

    constructor() payable {
        _users[0] = address(1);
        _users[1] = address(2);
        _users[2] = address(3);
        _users[3] = address(4);

        _deployer = new Deployer();
        (_token, _walletFactory, _registry) = _deployer.deploy(_users);
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

    // Try POC happy path first
    function attack() public onlyTestingLevel(TestingLevel.Solved) {
        _attack();
    }

    function attackWithSomething()
        external
        onlyTestingLevel(TestingLevel.UnsolvedSomething)
    {
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

    function echidna_sender_cannot_steal_funds() public view returns (bool) {
        return
            _token.balanceOf(msg.sender) <
            _deployer.AMOUNT_TOKENS_DISTRIBUTED();
    }

    // @audit-info if receive is missing, educated guess will fail
    receive() external payable {}
}
