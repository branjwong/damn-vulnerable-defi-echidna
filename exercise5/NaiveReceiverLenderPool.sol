// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NaiveReceiverLenderPool is ReentrancyGuard {
    using Address for address;

    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan

    function fixedFee() external pure returns (uint256) {
        return FIXED_FEE;
    }

    function flashLoan(
        address borrower,
        uint256 borrowAmount
    ) external payable nonReentrant {
        require(
            msg.value == FIXED_FEE,
            "Flash loan fee must be equal to FIXED_FEE"
        );

        uint256 balanceBefore = address(this).balance - msg.value;
        require(
            balanceBefore >= borrowAmount + FIXED_FEE,
            "Not enough ETH in pool"
        );

        require(borrower.isContract(), "Borrower must be a deployed contract");
        // Transfer ETH and handle control to receiver
        borrower.functionCallWithValue(
            abi.encodeWithSignature("receiveEther(uint256)", FIXED_FEE),
            borrowAmount + msg.value
        );

        require(
            address(this).balance >= balanceBefore + FIXED_FEE,
            "Flash loan hasn't been paid back"
        );
    }

    // Allow deposits of ETH
    receive() external payable {}
}
