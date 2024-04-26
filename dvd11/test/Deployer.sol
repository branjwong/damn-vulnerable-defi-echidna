pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@common/DamnValuableToken.sol";
import "../src/WalletRegistry.sol";

contract Deployer {
    uint256 public constant AMOUNT_TOKENS_DISTRIBUTED = 40 ether;

    function deploy(
        address[] calldata users
    )
        external
        payable
        returns (
            DamnValuableToken token,
            GnosisSafeProxyFactory walletFactory,
            WalletRegistry registry
        )
    {
        GnosisSafe masterCopy = new GnosisSafe();
        walletFactory = new GnosisSafeProxyFactory();
        token = new DamnValuableToken();
        registry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(token),
            users
        );

        for (uint256 i = 0; i < users.length; i++) {
            registry.addBeneficiary(users[i]);
        }

        token.transfer(address(registry), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
