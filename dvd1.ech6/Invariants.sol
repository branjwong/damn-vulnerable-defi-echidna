pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./ReceiverUnstoppable.sol";
import "./UnstoppableLender.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna contracts/unstoppable/Invariants.sol --contract UnstoppableTests --config contracts/unstoppable/config.yaml --seed 5561464089567990393
///      ```
contract UnstoppableTests {
    using Address for address payable;

    uint256 constant DVT_IN_LENDER = 10;
    uint256 constant INITIAL_ATTACKER_BALANCE = 1;

    // Attacker address configured in config.yaml as `sender`.
    address attacker = 0x68DDC84B01245762D5DEbBafA880EfE3999129bc;

    DamnValuableToken token;

    UnstoppableLender pool;

    constructor() {
        token = new DamnValuableToken();
        pool = new UnstoppableLender(address(token));

        token.approve(address(pool), DVT_IN_LENDER);
        pool.depositTokens(DVT_IN_LENDER);

        token.transfer(attacker, INITIAL_ATTACKER_BALANCE);
    }

    // Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        // Return all tokens to the pool
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Transfer of tokens failed"
        );
    }

    // We want to test whether the balance of the receiver contract can be decreased.
    // @audit It is bad if the receiver's balance decreases because the caller of NaiveReceiverLenderlender:flashLoan is designed to pay fees, not the receiver.
    function echidna_test_can_always_flash_loan() public returns (bool) {
        pool.flashLoan(10);
        return true;
    }
}
