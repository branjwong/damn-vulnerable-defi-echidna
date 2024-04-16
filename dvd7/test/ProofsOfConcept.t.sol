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
        // uint256 tokensInPool = _deployer.TOKENS_IN_POOL();
        // assertEq(_token.balanceOf(_attacker), 0);
        // assertEq(_token.balanceOf(address(_pool)), tokensInPool);
        // vm.startPrank(_attacker);
        // Attack attack = new Attack(_token, _gov, _pool);
        // attack.attack(tokensInPool);
        // assertEq(_token.balanceOf(_attacker), tokensInPool);
        // assertEq(_token.balanceOf(address(_pool)), 0);
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
    // address _owner;
    // DamnValuableTokenSnapshot private _token;
    // SelfiePool private _pool;
    // SimpleGovernance private _gov;
    // constructor(
    //     DamnValuableTokenSnapshot token,
    //     SimpleGovernance gov,
    //     SelfiePool pool
    // ) {
    //     _owner = msg.sender;
    //     _token = token;
    //     _gov = gov;
    //     _pool = pool;
    // }
    // function attack(uint256 amount) external {
    //     require(msg.sender == _owner, "Only _owner can call");
    //     _pool.flashLoan(amount);
    //     vm.warp(2 days + 1 seconds);
    //     _gov.executeAction(1);
    // }
    // function receiveTokens(address token, uint256 amount) external {
    //     _token.snapshot();
    //     _token.getBalanceAtLastSnapshot(address(this));
    //     _gov.queueAction(
    //         address(_pool),
    //         abi.encodeWithSignature("drainAllFunds(address)", _owner),
    //         0
    //     );
    //     ERC20Snapshot(token).transfer(address(_pool), amount);
    // }
}
