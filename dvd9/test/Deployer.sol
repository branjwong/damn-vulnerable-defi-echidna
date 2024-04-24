pragma solidity 0.5.16;

import {UniswapV2Factory} from "@uniswap/v2-core/contracts/UniswapV2Factory.sol";
import {UniswapV2Router02} from "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "@common/DamnValuableToken.sol";
import {PuppetV2Pool} from "../src/PuppetV2Pool.sol";

contract Deployer {
    using Address for address payable;

    function deploy(
        uint256 uniswapInitialTokenReserve,
        uint256 uniswapInitialWethReserve,
        uint256 poolInitialTokenBalance
    )
        external
        payable
        returns (DamnValuableToken token, Weth weth, PuppetV2Pool pool)
    {
        // Deploy tokens to be traded
        DamnVulnerableToken token = new DamnValuableToken();
        Weth weth = new WETH();

        // Deploy Uniswap Factory and Router
        UniswapV2Factory uniswapFactory = new UniswapV2Factory(address(0));

        UniswapV2Router02 uniswapRouter = new UniswapV2Router02(
            address(uniswapFactory),
            address(_weth)
        );

        // Create Uniswap pair against WETH and add liquidity
        _token.approve(address(uniswapRouter), uniswapInitialTokenReserve);
        uniswapRouter.addLiquidityETH{value: uniswapInitialWethReserve}(
            address(_token),
            uniswapInitialTokenReserve, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            address(this),
            block.timestamp * 2 days
        );

        address uniswapExchange = uniswapFactory.getPair[address(_token)][
            address(_weth)
        ];

        PuppetV2Pool pool = new PuppetV2Pool(
            address(_weth),
            address(_token),
            address(_uniswapPair),
            address(uniswapFactory)
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
