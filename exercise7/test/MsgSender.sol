// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

contract MsgSenderTest is Test {
    ContractA contractA;
    ContractB contractB;

    function testMsgSender() public {
        contractA = new ContractA();
        contractB = new ContractB(contractA);

        console.log("MsgSenderTest:addr=%s", address(this));
        console.log("ContractA:addr=%s", address(contractA));
        console.log("ContractB:addr=%s", address(contractB));

        // msg.sender == forge_test_runner:addr
        console.log("MsgSenderTest:msg.sender=%s", msg.sender);

        contractB.getMsgSender();
    }
}

contract ContractA {
    function getMsgSender() external returns (address) {
        // msg.sender == ContractB:addr
        console.log("ContractA:msg.sender=%s", msg.sender);

        return msg.sender;
    }
}

contract ContractB {
    ContractA contractA;

    constructor(ContractA _contractA) {
        contractA = _contractA;
    }

    function getMsgSender() external returns (address) {
        // msg.sender == MsgSenderTest:addr
        console.log("ContractB:msg.sender=%s", msg.sender);

        contractA.getMsgSender();
        return msg.sender;
    }
}
