// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    IERC20 public immutable damnValuableToken;

    constructor(address tokenAddress) {
        damnValuableToken = IERC20(tokenAddress);
    }

    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        // @audit-info storage, calldata, memory. Memory is temporary, calldata is readonly memory, storage is persistent.
        // https://docs.alchemy.com/docs/when-to-use-storage-vs-memory-vs-calldata-in-solidity
        bytes calldata data
    ) external nonReentrant {
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        damnValuableToken.transfer(borrower, borrowAmount);
        // @audit-info not a delegatecall, a call.
        // https://ethereum.stackexchange.com/questions/3667/difference-between-call-callcode-and-delegatecall
        // https://medium.com/0xmantle/solidity-series-part-3-call-vs-delegatecall-8113b3c76855
        // @audit-info call(): Reverts are not bubbled up normally, but OZ's package handles bubbling up.
        // @audit-info call(): calls to non-contracts succeeds normally, but OZ's package handles makes them fail.

        // @audit what if target = DVT, function = approve?
        target.functionCall(data);

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}
