// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProofsOfConcept is Test {
    address attacker = makeAddr("attacker");

    constructor() {}

    function testHappyPath() external {}

    function testAttack() external {}
}
