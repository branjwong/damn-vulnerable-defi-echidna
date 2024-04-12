// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
// @audit does there exist a FlashLoan protocol that loans eth?
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping(address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        require(
            // @audit balanceBefore doesn't take into account whether flash loan was paid back to the right user. Should check that sum(balances) is also equal to balanceBefore, or something similar.
            address(this).balance >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}
