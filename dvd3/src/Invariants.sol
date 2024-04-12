pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna contracts/naive-receiver/Invariants.sol --contract InvariantTests --config contracts/naive-receiver/config.yaml
///      ```
contract InvariantTests {
    using Address for address payable;

    constructor() payable {}

    function echidna_test_receiver_balance_cannot_decrease()
        public
        view
        returns (bool)
    {
        return true;
    }
}
