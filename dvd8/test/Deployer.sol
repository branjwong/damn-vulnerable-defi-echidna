pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@common/DamnValuableToken.sol";
import "@common/uniswap/UniswapDeployer.sol";
import "@common/uniswap/UniswapV1Factory.sol";
// import {Test, console} from "forge-std/Test.sol";

import "../src/PuppetPool.sol";

contract Deployer {
    using Address for address payable;

    uint256 public constant POOL_INITIAL_TOKEN_BALANCE = 100_000 ether;
    uint256 public constant UNISWAP_INITIAL_TOKEN_RESERVE = 10 ether;
    uint256 public constant UNISWAP_INITIAL_ETH_RESERVE = 10 ether;

    DamnValuableToken _token;

    function deploy()
        external
        payable
        returns (
            DamnValuableToken token,
            PuppetPool pool,
            UniswapV1Exchange exchange
        )
    {
        require(
            msg.value == UNISWAP_INITIAL_ETH_RESERVE,
            "Deployer: incorrect ETH"
        );

        UniswapDeployer deployer = new UniswapDeployer();

        // Deploy token to be traded in Uniswap
        token = new DamnValuableToken();
        _token = token;

        // Deploy a exchange that will be used as the factory template
        UniswapV1Exchange exchangeTemplate = deployer.deployExchange();

        // Deploy factory, initializing it with the address of the template exchange
        UniswapV1Factory factory = deployer.deployFactory();
        factory.initializeFactory(address(exchangeTemplate));

        // Create a new exchange for the token, and retrieve the deployed exchange's address
        exchange = UniswapV1Exchange(factory.createExchange(address(token)));

        // Deploy the lending pool
        pool = new PuppetPool(address(token), address(exchange));
        token.transfer(address(pool), POOL_INITIAL_TOKEN_BALANCE);

        // Add initial token and ETH liquidity to the pool
        // There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.
        token.approve(address(exchange), UNISWAP_INITIAL_TOKEN_RESERVE);

        exchange.addLiquidity{value: UNISWAP_INITIAL_ETH_RESERVE}(
            0, // min_liquidity
            UNISWAP_INITIAL_TOKEN_RESERVE,
            block.timestamp + 2 days // deadline
        );
    }

    function transfer(address to, uint256 value) external {
        _token.transfer(to, value);
    }

    // function _logState(
    //     PuppetPool pool,
    //     DamnValuableToken token,
    //     UniswapV1Exchange exchange,
    //     UniswapV1Factory factory,
    //     UniswapV1Exchange exchangeTemplate
    // ) internal view {
    //     console.log("Deployer: deployed PuppetPool at %s", address(pool));
    //     console.log(
    //         "Deployer: deployed DamnValuableToken at %s",
    //         address(token)
    //     );
    //     console.log(
    //         "Deployer: deployed UniswapV1Exchange at %s",
    //         address(exchange)
    //     );
    //     console.log(
    //         "Deployer: deployed UniswapV1Factory at %s",
    //         address(factory)
    //     );
    //     console.log(
    //         "Deployer: deployed exchangeTemplate at %s",
    //         address(exchangeTemplate)
    //     );
    // }
}
