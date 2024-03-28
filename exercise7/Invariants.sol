pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./SideEntranceLenderPool.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna contracts/side-entrance/Invariants.sol --contract SideEntranceTests --config contracts/side-entrance/config.yaml --seed 5561464089567990393
///      ```

contract SideEntranceTests is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;

    uint256 constant INITIAL_POOL_BALANCE = 1000 ether;
    uint256 initialPoolBalance;

    bool enableWithdraw;
    bool enableDeposit;
    uint256 depositAmount;

    constructor() payable {
        require(msg.value >= INITIAL_POOL_BALANCE);

        PoolDeployer p = new PoolDeployer();

        pool = p.deployNewPool{value: INITIAL_POOL_BALANCE}();
        initialPoolBalance = address(pool).balance;
    }

    receive() external payable {}

    function withdraw() external {
        pool.withdraw();
    }

    function execute() external payable override {
        pool.deposit{value: msg.value}();
    }

    function flashLoan(uint256 _amount) public {
        pool.flashLoan(_amount);
    }

    // We want to test whether the balance of the receiver contract can be decreased.
    function echidna_test_pool_retains_funds() public view returns (bool) {
        return address(pool).balance >= INITIAL_POOL_BALANCE;
    }

    // We want to test whether the balance of the receiver contract can be decreased.
    function echidna_test_pool_retains_some_funds() public view returns (bool) {
        return address(pool).balance > 0;
    }

    // // We want to test whether the balance of the receiver contract can be decreased.
    // function echidna_test_pool_can_always_flash_loan() public returns (bool) {
    //     pool.flashLoan(1);
    //     return true;
    // }

    // function echidna_test_deployer_can_withdraw_funds() public returns (bool) {
    //     pool.withdraw();
    //     pool.deposit{value: INITIAL_POOL_BALANCE}();
    //     return true;
    // }
}

contract PoolDeployer {
    function deployNewPool() public payable returns (SideEntranceLenderPool) {
        SideEntranceLenderPool p;
        p = new SideEntranceLenderPool();
        p.deposit{value: msg.value}();

        return p;
    }
}
