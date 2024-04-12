// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)

 * @dev A simple pool to get flash loans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable liquidityToken;

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        // @audit-info check if enough
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));
        require(amount <= balanceBefore, "Not enough token balance");

        require(
            msg.sender.isContract(),
            "Borrower must be a deployed contract"
        );

        // @audit-info transfer to flash loan caller
        liquidityToken.transfer(msg.sender, amount);

        // @audit-info call calling contract's receiveFlashLoan fn
        msg.sender.functionCall(
            abi.encodeWithSignature("receiveFlashLoan(uint256)", amount)
        );

        // @audit-info check if flash loan was paid back
        require(
            liquidityToken.balanceOf(address(this)) >= balanceBefore,
            "Flash loan not paid back"
        );
    }
}
