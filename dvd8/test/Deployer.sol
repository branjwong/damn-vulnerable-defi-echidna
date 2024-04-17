pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@common/DamnValuableToken.sol";

import "../src/PuppetPool.sol";

contract Deployer {
    using Address for address payable;

    function deploy()
        external
        payable
        returns (DamnValuableToken token, PuppetPool pool)
    {
        token = new DamnValuableToken();
        pool = new PuppetPool(address(token));
    }
}
