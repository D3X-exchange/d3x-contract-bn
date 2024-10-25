// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "../chainlinkClient/ChainlinkClientInterface.sol";
import "../twapPriceGetter/TWAPPriceGetterInterface.sol";
import "./D3xManagerEvent.sol";

import "./D3xManagerType.sol";

interface D3xManagerInterface7 is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
//ChainlinkClientInterface,
//TWAPPriceGetterInterface,
D3xManagerEvent {

    function getGlobalConfig() external view returns (D3xManagerType.GlobalConfig memory);

    //function getSupportedCurrency() external view returns (address[] memory);

    function getCurrency(address currency) external view returns (D3xManagerType.Currency memory);

    //function getCurrencyNested() external view returns (D3xManagerType.Currency[] memory);

    function getPair(uint16 pairNumber) external view returns (D3xManagerType.Pair memory);

    function getPairCurrency(uint16 pairCurrencyNumber) external view returns (D3xManagerType.PairCurrency memory);

    function getActivePairCurrency() external view returns (uint256[] memory);

    //function getActivePairCurrencyDetail(uint16 pairNumber) external view returns (D3xManagerType.ActivePairCurrencyDetail memory);

    function getActivePairCurrencyNested(
    ) external view returns (
        D3xManagerType.GetActivePairCurrencyNestedResponse[] memory activePairCurrencyResponse
    );

    function getPairOI(uint16 pairCurrencyNumber, uint32 windowId) external view returns (D3xManagerType.PairCurrencyOIWindow memory);

    function getPairWindowId(uint32 timestamp) external view returns (uint32);

    function getPerson(address who) external view returns (D3xManagerType.Person memory);

    function getTrade(uint64 tradeNumber) external view returns (D3xManagerType.Trade memory);

    function getPersonTrade(address who, uint16 pairCurrencyNumber) external view returns (uint256[] memory);

    function getPersonClosedTrade(address who, uint16 pairCurrencyNumber) external view returns (uint64[] memory);

    function getPersonTradeNested(address who, uint16 pairCurrencyNumber) external view returns (
        D3xManagerType.Trade[] memory personTrade,
        D3xManagerType.Trade[] memory personClosedTrade
    );

    function getOrder(uint64 orderNumber) external view returns (D3xManagerType.Order memory);

    function getSupportedSupplier() external view returns (address[] memory);

    function getSupportedLimitTrigger() external view returns (address[] memory);

    function getChainlinkRequestIdToOrderId(bytes32 requestId) external view returns (uint256);

    //function getOpeningOrClosingTrade() external view returns(uint256[] memory);

    function getPersonCurrency(address currency, address who) external view returns (D3xManagerType.PersonCurrency memory);

    function setGlobalConfig(D3xManagerType.GlobalConfig calldata input) external;

    //function setSupportedCurrency(address[] calldata adds, address[] calldata removes) external;

    function setCurrency(address currency, D3xManagerType.Currency calldata input) external;

    function setPair(D3xManagerType.SetPairRequest[] calldata inputs) external;

    function setPairCurrency(D3xManagerType.SetPairCurrencyRequest[] calldata inputs) external;

    function setActivePairCurrency(
        uint16[] calldata addPairCurrency,
        uint16[] calldata removePairCurrency
    ) external;

    function setPairCurrencyDepth(D3xManagerType.SetPairCurrencyDepthRequest[] calldata input) external;

    function setBorrowingFeeRate(D3xManagerType.SetBorrowingFeeRateRequest[] calldata input) external;

    function setSupportedSupplier(address[] calldata node) external;

    function setSupportedLimitTrigger(address[] calldata trigger) external;

    function packData(uint64 oracleTimestamp64, uint64 low, uint64 high, uint64 openOrPriceData64) external pure returns (uint256);
}
