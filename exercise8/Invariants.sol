pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna contracts/the-rewarder/Invariants.sol --contract TheRewarderTests --config contracts/the-rewarder/config.yaml --seed 1
///      ```
contract TheRewarderTests {
    TheRewarderPool pool;
    DamnValuableToken token;
    FlashLoanerPool flashLoanPool;

    uint256 constant AMOUNT_TO_DEPOSIT = 5;
    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    constructor() {
        TokenDeployer deployer = new TokenDeployer();
        token = deployer.deployToken();

        pool = new TheRewarderPool(address(token));
        flashLoanPool = new FlashLoanerPool(address(token));

        deployer.transfer(address(flashLoanPool), FLASH_LOAN_POOL_AMOUNT);
    }

    function flashLoan(uint256 amount) external {
        flashLoanPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        token.approve(address(pool), amount);
        pool.deposit(amount);

        pool.withdraw(amount);

        token.approve(address(flashLoanPool), amount);
        token.transfer(address(flashLoanPool), amount);
    }

    function echidna_test_can_always_put_money_in_and_withdraw()
        public
        returns (bool)
    {
        token.approve(address(pool), AMOUNT_TO_DEPOSIT);
        pool.deposit(AMOUNT_TO_DEPOSIT);

        pool.withdraw(AMOUNT_TO_DEPOSIT);

        return true;
    }
}

contract TokenDeployer {
    DamnValuableToken token;

    function deployToken() external returns (DamnValuableToken) {
        token = new DamnValuableToken();
        return token;
    }

    function transfer(address to, uint256 amount) external {
        token.approve(to, amount);
        token.transfer(to, amount);
    }
}
