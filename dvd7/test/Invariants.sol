pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@common/DamnValuableNFT.sol";

import "../src/Exchange.sol";
import "../src/TrustfulOracle.sol";
import "./Deployer.sol";

/// @dev Run the template with
///      ```
///      cd repo
///      solc-select use 0.8.0
///      echidna test/Invariants.sol --contract Echidna --config test/echidna.config.yaml
///      ```
contract Echidna {
    using Address for address payable;

    address _owner;

    Deployer _deployer;
    ExchangeHarness _exchange;
    DamnValuableNFT _nft;
    TrustfulOracle _oracle;

    constructor() payable {
        _owner = msg.sender;

        Exchange exchange;
        _deployer = new Deployer();

        (exchange, _nft, _oracle) = _deployer.deploy{
            value: _deployer.EXCHANGE_INITIAL_ETH_BALANCE()
        }();

        _exchange = new ExchangeHarness(exchange);
    }

    // //////////////
    // EDUCATED GUESS
    // //////////////

    // /////////////////
    // SUSPECT FUNCTIONS
    // /////////////////

    // function flashLoan(uint256 amount) external {
    //     _pool.flashLoan(amount);
    // }

    // function executeAction(uint256 actionId) external {
    //     _gov.executeAction(actionId);
    // }

    // ////////////////////
    // INVARIANT PROPERTIES
    // ////////////////////

    function echidna_exchange_must_retain_ETH_after_all_NFTs_sold()
        public
        view
        returns (bool)
    {
        return
            _exchange.salesCount() > 0 ||
            _exchange.getBalance() >= _deployer.EXCHANGE_INITIAL_ETH_BALANCE();
    }
}

contract ExchangeHarness {
    Exchange _exchange;

    constructor(Exchange exchange) {
        _exchange = exchange;
    }

    uint256 public salesCount = 0;

    function buyOne() external payable {
        _exchange.buyOne{value: msg.value}();
        salesCount++;
    }

    function sellOne(uint256 tokenId) external {
        _exchange.sellOne(tokenId);
        salesCount--;
    }

    function getBalance() external view returns (uint256) {
        return address(_exchange).balance;
    }
}
