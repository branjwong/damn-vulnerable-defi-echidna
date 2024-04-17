pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@common/DamnValuableNFT.sol";

import "../src/Exchange.sol";
import "../src/TrustfulOracle.sol";
import "../src/TrustfulOracleInitializer.sol";

contract Deployer {
    using Address for address payable;

    uint256 public immutable EXCHANGE_INITIAL_ETH_BALANCE = 9990 ether;
    uint256 public immutable INITIAL_NFT_PRICE = 999 ether;
    string public NFT_SYMBOL = "DVNFT";

    address[] _sources = [
        0xA73209FB1a42495120166736362A1DfA9F95A105,
        0xe92401A4d3af5E446d93D11EEc806b1462b39D15,
        0x81A5D6E50C214044bE44cA0CB057fe119097850c
    ];
    string[] _symbols;
    uint256[] _prices;

    function deploy()
        external
        payable
        returns (Exchange exchange, DamnValuableNFT nft, TrustfulOracle oracle)
    {
        _symbols = [NFT_SYMBOL, NFT_SYMBOL, NFT_SYMBOL];
        _prices = [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE];

        TrustfulOracleInitializer initializer = new TrustfulOracleInitializer(
            _sources,
            _symbols,
            _prices
        );
        oracle = initializer.oracle();
        exchange = new Exchange(address(oracle));

        payable(msg.sender).sendValue(msg.value);

        nft = exchange.token();
    }
}
