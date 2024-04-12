// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/liquidityToken/ERC20/ERC20.sol";
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      cd exercise8
///      echidna contracts/the-rewarder/Invariants.sol --contract TheRewarderTests --config contracts/the-rewarder/config.yaml --seed 1
///      ```

contract RewarderTaskDeployer {
    uint256 private TOKENS_IN_LENDER_POOL = 1_000_000 ether;
    uint256 private TOKENS_PER_USER = 100 ether;

    function deployPoolsAndToken()
        public
        payable
        returns (DamnValuableToken, FlashLoanerPool, TheRewarderPool)
    {
        DamnValuableToken token;
        FlashLoanerPool pool;
        TheRewarderPool rewarder;

        token = new DamnValuableToken();
        pool = new FlashLoanerPool(address(token));
        rewarder = new TheRewarderPool(address(token));

        token.transfer(address(pool), TOKENS_IN_LENDER_POOL);

        // deposit tokens to the rewarder pool (simulate a deposit of 4 users)
        token.approve(address(rewarder), TOKENS_PER_USER * 4);
        rewarder.deposit(TOKENS_PER_USER * 4);
        return (token, pool, rewarder);
    }
}

contract TheRewarderTests {
    TheRewarderPool rewarder;
    DamnValuableToken liquidityToken;
    RewardToken rewardToken;
    FlashLoanerPool pool;

    uint256 REWARDS_ROUND_MIN_DURATION = 5 days;
    uint256 reward;

    uint256 flashLoanAmount;

    bool private depositEnabled;
    bool private withdrawalEnabled;
    bool private rewardsDistributionEnabled;

    constructor() {
        RewarderTaskDeployer deployer = new RewarderTaskDeployer();
        (liquidityToken, pool, rewarder) = deployer.deployPoolsAndToken();
        rewardToken = rewarder.rewardToken();
    }

    function receiveFlashLoan(uint256 amount) external {
        require(
            msg.sender == address(pool),
            "Only pool can call this function."
        );
        // call selected functions
        selectFunctionsToCallInCallback();
        // get max reward amount for checking the INVARIANT
        reward = rewardToken.balanceOf(address(this));
        // repay the loan
        liquidityToken.transfer(address(pool), amount);
    }

    // @audit-info This pattern of defining functions to be called in a callback could be a pattern to be used to test how callbacks can be defined to exploit
    /**
     * @notice functions to be called in callback
     * @dev order must be defined by a user
     */
    function selectFunctionsToCallInCallback() internal {
        // @audit-info Needed to understand codebase to understand what order functions could be reasonably called in.
        // deposit to the rewarder with prior approval
        if (depositEnabled) {
            liquidityToken.approve(address(rewarder), flashLoanAmount);
            rewarder.deposit(flashLoanAmount);
        }
        // withdraw from the rewarder
        if (withdrawalEnabled) {
            rewarder.withdraw(flashLoanAmount);
        }
        // distribute rewards
        if (rewardsDistributionEnabled) {
            rewarder.distributeRewards();
        }
    }

    function setEnableDeposit(bool _enabled) external {
        depositEnabled = _enabled;
    }

    function setEnableWithdrawal(bool _enabled) external {
        withdrawalEnabled = _enabled;
    }

    function setRewardsDistributionEnabled(bool _enabled) external {
        rewardsDistributionEnabled = _enabled;
    }

    function flashLoan(uint256 _amount) public {
        uint256 lastRewardsTimestamp = rewarder.lastRecordedSnapshotTimestamp();
        require(
            block.timestamp >=
                lastRewardsTimestamp + REWARDS_ROUND_MIN_DURATION,
            "It is useless to call flashloan if no rewards can be taken as ETH is precious."
        );
        require(
            _amount <= liquidityToken.balanceOf(address(pool)),
            "Cannot borrow more than it is in the pool."
        );
        // set _amount into storage to have the value available in selectFunctionsToCallInCallback()
        flashLoanAmount = _amount;
        // call flashloan
        pool.flashLoan(flashLoanAmount);
    }

    function testRewards() public view {
        assert(reward < 99 ether);
    }
}
