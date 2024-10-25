// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerType.sol";

interface D3xManagerEvent {

    //example:  123.XXXyyy
    //next available
    //0xx order 016
    //1xx open 134
    //2xx cancel 203
    //3xx trigger 310
    //4xx close 415
    //5xx timeout 513
    //6xx miscellaneous 617
    //7xx system 710


    event OrderRequest(uint256 orderNumber, bytes32 chainlinkRequestId);

    event TradePivot(uint256 tradeNumber, uint256 oldTradeState, uint256 newTradeState);

    event OrderFulfill(uint64 orderNumber, uint8 orderType, address supplier, uint32 oracleTimestamp, uint64 spotPriceOrOpenPrice, uint64 highPrice, uint64 lowPrice);
}
