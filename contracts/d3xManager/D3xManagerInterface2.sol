// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "../chainlinkClient/ChainlinkClientInterface.sol";
import "../twapPriceGetter/TWAPPriceGetterInterface.sol";
import "./D3xManagerEvent.sol";

import "./D3xManagerType.sol";

interface D3xManagerInterface2 is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
//ChainlinkClientInterface,
//TWAPPriceGetterInterface,
D3xManagerEvent {

    function openTradeMarket(
        D3xManagerType.OpenTradeRequest calldata request
    )
    external;

    function closeTradeMarket(
        uint64 tradeNumber
    ) external;

    function openTradeLimit(
        D3xManagerType.OpenTradeRequest calldata request
    )
    external;

    function cancelTradeLimit(
        uint64 tradeNumber
    )
    external;

    function triggerLimitOrder(
        D3xManagerType.LimitTradeTriggerRequest[] calldata params
    ) external;

}
