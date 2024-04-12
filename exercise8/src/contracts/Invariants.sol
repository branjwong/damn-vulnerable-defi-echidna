// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      cd exercise8
///      echidna contracts/the-rewarder/Invariants.sol --contract TheRewarderTests --config contracts/the-rewarder/config.yaml --seed 1
///      ```
contract TheRewarderTests {
    TheRewarderPool pool;
    DamnValuableToken token;

    uint256 constant AMOUNT_TO_DEPOSIT = 5;
    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    constructor() {
        TokenDeployer deployer = new TokenDeployer();
        token = deployer.deployToken();

        pool = new TheRewarderPool(address(token));

        deployer.transfer(address(this), FLASH_LOAN_POOL_AMOUNT);
        deployer.transfer(address(pool), AMOUNT_TO_DEPOSIT);
    }

    function echidna_wins_a_fair_amount() public view returns (bool) {
        // ...

        return token.balanceOf(address(pool)) > AMOUNT_TO_DEPOSIT - 1;
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
