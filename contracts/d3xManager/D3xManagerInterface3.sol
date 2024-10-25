// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "../chainlinkClient/ChainlinkClientInterface.sol";
import "../twapPriceGetter/TWAPPriceGetterInterface.sol";
import "./D3xManagerEvent.sol";

import "./D3xManagerType.sol";

interface D3xManagerInterface3 is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
//ChainlinkClientInterface,
//TWAPPriceGetterInterface,
D3xManagerEvent {

    function openTradeMarketCallback(uint64 orderNumber) external returns (bool);

    function openTradeMarketProcess(uint64 orderNumber) external;

    function openTradeLimitCallback(uint64 orderNumber) external returns (bool);

    function openTradeLimitProcess(uint64 orderNumber) external;
}
