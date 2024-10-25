// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "../chainlinkClient/ChainlinkClientInterface.sol";
import "../twapPriceGetter/TWAPPriceGetterInterface.sol";
import "./D3xManagerEvent.sol";

import "./D3xManagerType.sol";

interface D3xManagerInterface1 is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
ChainlinkClientInterface,
TWAPPriceGetterInterface,
D3xManagerEvent {

    function requestPriceOrder(
        uint64 tradeNumber,
        uint8 orderType,
        uint32 fromPriceTimestamp,
        uint32 fromTimestamp,
        uint32 toTimestamp
    )
    external
    returns (uint256 orderNumber);

    function fulfillRequestPriceOrder(
        bytes32 chainlinkRequestId,
        uint256 priceData
    )
    external;

    function fetchFeedPrice(uint16 pairNumber) external view returns (uint64);
}
