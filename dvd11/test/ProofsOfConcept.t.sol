// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import {DamnValuableToken} from "@common/DamnValuableToken.sol";
import {GnosisSafe} from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import {GnosisSafeProxy} from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

import {Deployer} from "./Deployer.sol";
import {WalletRegistry} from "../src/WalletRegistry.sol";

contract ProofsOfConcept is Test {
    address _attacker = makeAddr("attacker");

    // Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.
    uint256 public constant ATTACKER_TOKENS = 1000 ether;
    uint256 public constant ATTACKER_ETH = 25 ether;

    Deployer _deployer;

    DamnValuableToken _token;
    GnosisSafeProxyFactory _walletFactory;
    WalletRegistry _walletRegistry;

    address _alice = makeAddr("alice");
    address _bob = makeAddr("bob");
    address _charlie = makeAddr("charlie");
    address _david = makeAddr("david");
    address[] _users = new address[](4);

    constructor() {
        _users[0] = _alice;
        _users[1] = _bob;
        _users[2] = _charlie;
        _users[3] = _david;

        _deployer = new Deployer();
        (_token, _walletFactory, _walletRegistry) = _deployer.deploy(_users);
    }

    function testHappyPath() external {
        vm.deal(_alice, 1000 ether);
        vm.startPrank(_alice);

        console.log("_users[0] %s", _users[0]);
        console.log("_users[1] %s", _users[1]);
        console.log("_users[2] %s", _users[2]);
        console.log("_users[3] %s", _users[3]);

        address[] memory _owners = new address[](1);
        _owners[0] = _alice;

        // create a wallet in Gnosis and register it in the registry using GnosisSafeProxyFactory::createProxyWithCallback
        // @audit-info Initializers: https://blog.openzeppelin.com/getting-the-most-out-of-create2
        GnosisSafeProxy proxy = _walletFactory.createProxyWithCallback(
            _walletRegistry.masterCopy(),
            // @audit-info initializer := abi.encode(methodName, args..)
            // @audit-info abi.encodeWithSelector trims the selector down to 8 bytes
            abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                _owners, // address[] calldata _owners
                uint256(1), // uint256 _threshold
                address(0), // address to
                0x0, // bytes calldata data
                address(0), // address fallbackHandler
                address(0), // address paymentToken
                uint256(0), // uint256 payment
                address(0) // address paymentReceiver
            ), // initializer
            1, // saltNonce
            _walletRegistry
        );

        // observe DVT balance
        console.log("Wallet DVT: %d", _token.balanceOf(address(proxy)));
        assertEq(_token.balanceOf(address(proxy)), 10000000000000000000);
    }

    // Try Echidna First
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
