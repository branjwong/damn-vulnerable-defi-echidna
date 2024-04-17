// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../src/DamnValuableNFT.sol";
import "../src/Exchange.sol";
import "../src/TrustfulOracle.sol";
import "./Deployer.sol";

contract ProofsOfConcept is Test {
    address _attacker = makeAddr("attacker");

    Deployer _deployer;
    Exchange _exchange;
    DamnValuableNFT _nft;
    TrustfulOracle _oracle;

    constructor() {
        _deployer = new Deployer();
        (_exchange, _nft, _oracle) = _deployer.deploy{
            value: _deployer.EXCHANGE_INITIAL_ETH_BALANCE()
        }();
    }

    function testHappyPath() external {
        LoanUser loanUser = new LoanUser(_exchange);
        vm.deal(address(loanUser), 1000 ether);

        loanUser.act();
    }

    function testAttack() external {
        vm.deal(_attacker, 0.1 ether);

        uint256 initialExchangeEthBalance = _deployer
            .EXCHANGE_INITIAL_ETH_BALANCE();
        assertEq(address(_attacker).balance, 0);
        assertEq(address(_exchange).balance, initialExchangeEthBalance);

        vm.startPrank(_attacker);
        Attack attack = new Attack(_exchange);
        attack.attack(initialExchangeEthBalance);

        assertEq(address(_attacker).balance, initialExchangeEthBalance);
        assertEq(address(_exchange).balance, 0);
    }
}

contract LoanUser is IERC721Receiver {
    Exchange _exchange;

    constructor(Exchange exchange) {
        _exchange = exchange;
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function act() external {
        // log ETH for user and exchange
        console.log("User ETH: %d", address(this).balance);
        console.log("Exchange ETH: %d", address(_exchange).balance);

        // log price of NFT
        uint256 initialPrice = _exchange.oracle().getMedianPrice("DVNFT");
        console.log("NFT price: %d", initialPrice);

        // buy NFT
        uint256 tokenId = _exchange.buyOne{value: initialPrice + 1 ether}();

        // log ETH for user and exchange
        console.log("User ETH: %d", address(this).balance);
        console.log("Exchange ETH: %d", address(_exchange).balance);

        // log price of NFT
        uint256 postBuyPrice = _exchange.oracle().getMedianPrice("DVNFT");
        console.log("NFT price: %d", postBuyPrice);

        // sell NFT
        _exchange.token().approve(address(_exchange), tokenId);
        _exchange.sellOne(tokenId);

        // log ETH for user and exchange
        console.log("User ETH: %d", address(this).balance);
        console.log("Exchange ETH: %d", address(_exchange).balance);

        // log price of NFT
        uint256 postSellPrice = _exchange.oracle().getMedianPrice("DVNFT");
        console.log("NFT price: %d", postSellPrice);
    }

    receive() external payable {}
}

contract Attack is Test {
    // Match found: 0xe92401A4d3af5E446d93D11EEc806b1462b39D15
    // Private Key: 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9

    // Match found: 0x81A5D6E50C214044bE44cA0CB057fe119097850c
    // Private Key: 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
    address _owner;

    address source = 0xe92401A4d3af5E446d93D11EEc806b1462b39D15;

    Exchange _exchange;
    constructor(Exchange exchange) {
        _owner = msg.sender;
        _exchange = exchange;
    }

    function attack(uint256 exchangeBalance) external payable {
        require(msg.sender == _owner, "Only _owner can call");
        require(msg.value >= 0.1 ether, "Need at least 0.1 ether");

        // get trusted price role

        // set price to 0.1 eth
        // buy

        // set price to exchangeBalance
        // sell
    }
}
