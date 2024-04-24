pragma solidity ^0.8.0;

import {UniswapV2Deployer} from "@common/uniswap/v2/UniswapV2Deployer.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "@common/DamnValuableToken.sol";
import {PuppetV2Pool} from "../src/PuppetV2Pool.sol";

contract Deployer {
    function deploy(
        uint256 uniswapInitialTokenReserve,
        uint256 uniswapInitialWethReserve,
        uint256 poolInitialTokenBalance
    )
        external
        payable
        returns (DamnValuableToken token, WETH weth, PuppetV2Pool pool)
    {
        UniswapV2Deployer deployUniswap = new UniswapV2Deployer();

        // Deploy tokens to be traded
        token = new DamnValuableToken();
        weth = new WETH();

        // Deploy Uniswap Factory and Router
        IUniswapV2Factory uniswapFactory = deployUniswap.factory(address(0));

        IUniswapV2Router02 uniswapRouter = deployUniswap.router(
            address(uniswapFactory),
            address(weth)
        );

        // Create Uniswap pair against WETH and add liquidity
        token.approve(address(uniswapRouter), uniswapInitialTokenReserve);
        uniswapRouter.addLiquidityETH{value: uniswapInitialWethReserve}(
            address(token),
            uniswapInitialTokenReserve, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            address(this),
            block.timestamp * 2 days
        );

        address uniswapPair = uniswapFactory.getPair(
            address(token),
            address(weth)
        );

        pool = new PuppetV2Pool(
            address(weth),
            address(token),
            uniswapPair,
            address(uniswapFactory)
        );

        token.transfer(address(pool), poolInitialTokenBalance);
    }
}
