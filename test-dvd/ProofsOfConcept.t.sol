// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "@common/DamnValuableToken.sol";
import "./Deployer.sol";

contract ProofsOfConcept is Test {
    address _user = makeAddr("user");
    address _attacker = makeAddr("attacker");

    // Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.
    uint256 public constant ATTACKER_TOKENS = 1000 ether;
    uint256 public constant ATTACKER_ETH = 25 ether;

    Deployer _deployer;

    DamnValuableToken _token;

    constructor() {
        _deployer = new Deployer();
        (_token) = _deployer.deploy();
    }

    function testHappyPath() external {
        vm.deal(_user, 1000 ether);
        vm.startPrank(_user);
    }

    // Try Echidna First
    function testAttack() external {
        vm.deal(_attacker, ATTACKER_ETH);
        deal(address(_token), _attacker, ATTACKER_TOKENS);
    }

    receive() external payable {}
}
