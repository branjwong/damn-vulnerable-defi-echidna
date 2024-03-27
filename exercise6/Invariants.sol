pragma solidity ^0.8.0;

import "./ReceiverUnstoppable.sol";
import "./UnstoppableLender.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna repo --contract UnstoppableTests --config repo/contracts/unstoppable/config.yaml
///      ```
contract UnstoppableTests {
    using Address for address payable;

    uint256 constant DVT_IN_RECEIVER = 10;

    IERC20 public immutable damnValuableToken;

    ReceiverUnstoppable receiver;
    UnstoppableLender pool;

    constructor() {
        damnValuableToken = new ERC20("DamnValuableToken", "DVT");
        damnValuableToken.mint(address(pool), DVT_IN_RECEIVER);
    }

    // We want to test whether the balance of the receiver contract can be decreased.
    // @audit It is bad if the receiver's balance decreases because the caller of NaiveReceiverLenderPool:flashLoan is designed to pay fees, not the receiver.
    function echidna_test_lender_balance_cannot_decrease()
        public
        view
        returns (bool)
    {
        return receiver.balance >= DVT_IN_RECEIVER;
    }
}
