// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "../chainlinkClient/ChainlinkClientInterface.sol";
import "../twapPriceGetter/TWAPPriceGetterInterface.sol";
import "./D3xManagerEvent.sol";

import "./D3xManagerType.sol";

interface D3xManagerInterface4 is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
//ChainlinkClientInterface,
//TWAPPriceGetterInterface,
D3xManagerEvent {

    function closeTradeMarketCallback(uint64 orderNumber) external returns (bool);

    function closeTradeMarketProcess(uint64 orderNumber) external;

    function closeTradeLimitCallback(uint64 orderNumber) external returns (bool);

    function closeTradeLimitProcess(uint64 orderNumber) external;
}
