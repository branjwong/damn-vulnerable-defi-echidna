// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "@common/DamnValuableToken.sol";

import "./Deployer.sol";
import "../src/WalletRegistry.sol";

contract ProofsOfConcept is Test {
    address _user = makeAddr("user");
    address _attacker = makeAddr("attacker");

    // Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.
    uint256 public constant ATTACKER_TOKENS = 1000 ether;
    uint256 public constant ATTACKER_ETH = 25 ether;

    Deployer _deployer;

    DamnValuableToken _token;
    WalletRegistry _walletRegistry;

    address _alice = makeAddr("alice");
    address _bob = makeAddr("bob");
    address _charlie = makeAddr("charlie");
    address _david = makeAddr("david");
    address[] _users = new address[](4);

    constructor() {
        _users.push(_alice);
        _users.push(_bob);
        _users.push(_charlie);
        _users.push(_david);
        _users.push(_attacker);

        _deployer = new Deployer();
        (_token, _walletRegistry) = _deployer.deploy(_users);
    }

    function testHappyPath() external {
        vm.deal(_user, 1000 ether);
        vm.startPrank(_user);

        // create a wallet in Gnosis and register it in the registry using GnosisSafeProxyFactory::createProxyWithCallback
        // observe DVT balance
    }

    function testAttack() external {
        vm.deal(_attacker, ATTACKER_ETH);
        deal(address(_token), _attacker, ATTACKER_TOKENS);

        for (uint256 i = 0; i < _users.length; i++) {
            address wallet = _walletRegistry.wallets(_users[i]);

            assertNotEq(wallet, address(0), "User did not register a wallet");

            assertFalse(_walletRegistry.beneficiaries(_users[i]));
        }

        assertEq(
            _token.balanceOf(address(_attacker)),
            _deployer.AMOUNT_TOKENS_DISTRIBUTED()
        );
    }

    receive() external payable {}
}
