pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@common/DamnValuableToken.sol";
import "../src/TrusterLenderPool.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna test/Invariants.sol --contract InvariantTests --config test/config.yaml
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

    // //////////////
    // EDUCATED GUESS
    // //////////////

    function flashLoan(
        uint256 borrowerAmount,
        address borrower,
        address target,
        address approveTarget,
        uint256 approveAmount
    ) external {
        lenderPool.flashLoan(
            borrowerAmount,
            borrower,
            target,
            // @audit-info hard to abstract this away from the fuzzer
            abi.encodeWithSignature(
                "approve(address,uint256)", //@audit-info no spaces between args
                approveTarget,
                approveAmount
            )
        );
    }

    // /////////////////
    // SUSPECT FUNCTIONS
    // /////////////////

    function transferFrom(address from, address to, uint256 amount) external {
        valuableToken.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) external {
        valuableToken.approve(spender, amount);
    }

    function transfer(address to, uint256 amount) external {
        valuableToken.transfer(to, amount);
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
