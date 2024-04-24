pragma solidity ^0.8.0;

import "@common/DamnValuableToken.sol";

contract Deployer {
    DamnValuableToken _token;

    function deploy() external payable returns (DamnValuableToken token) {
        token = new DamnValuableToken();
    }
}
