pragma solidity ^0.8.0;

import "./FlashLoanReceiver.sol";
import "./NaiveReceiverLenderPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna contracts/naive-receiver/Invariants.sol --contract InvariantTests --config contracts/naive-receiver/config.yaml
///      ```
contract InvariantTests {
    using Address for address payable;

    // We will send ETHER_IN_POOL to the flash loan pool.
    uint256 constant ETHER_IN_POOL = 1000e18;
    // We will send ETHER_IN_RECEIVER to the flash loan receiver.
    uint256 constant ETHER_IN_RECEIVER = 10e18;

    NaiveReceiverLenderPool pool;
    FlashLoanReceiver receiver;

    constructor() payable {
        pool = new NaiveReceiverLenderPool();
        receiver = new FlashLoanReceiver(payable(address(pool)));

        payable(address(pool)).sendValue(ETHER_IN_POOL);
        payable(address(receiver)).sendValue(ETHER_IN_RECEIVER);
    }

    // We want to test whether the balance of the receiver contract can be decreased.
    // @audit It is bad if the receiver's balance decreases because the caller of NaiveReceiverLenderPool:flashLoan is designed to pay fees, not the receiver.
    function echidna_test_receiver_balance_cannot_decrease()
        public
        view
        returns (bool)
    {
        return address(receiver).balance >= ETHER_IN_RECEIVER;
    }
}
