pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@common/DamnValuableToken.sol";
import "@common/uniswap/UniswapDeployer.sol";
import "@common/uniswap/UniswapV1Exchange.sol";

import "../src/PuppetPool.sol";

contract Deployer {
    using Address for address payable;

    uint256 public constant POOL_TOKENS = 100000;

    function deploy()
        external
        payable
        returns (DamnValuableToken token, PuppetPool pool)
    {
        UniswapDeployer deployer = new UniswapDeployer();
        UniswapV1Exchange exchange = deployer.deployExchange();

        token = new DamnValuableToken();
        pool = new PuppetPool(address(token), address(exchange));

        token.transfer(address(pool), POOL_TOKENS);
    }
}
