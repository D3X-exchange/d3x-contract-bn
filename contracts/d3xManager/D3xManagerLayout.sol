// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";
import "../chainlinkClient/ChainlinkClientLayout.sol";
import "../twapPriceGetter/TWAPPriceGetterLayout.sol";

import "./D3xManagerType.sol";
import "./D3xManagerLayoutForStruct.sol";

contract D3xManagerLayout is
OwnableLayout,
NameServiceRefLayout,
ChainlinkClientLayout,
TWAPPriceGetterLayout {

    mapping(uint256 => D3xManagerType.GlobalConfig) internal _globalConfig;

    //EnumerableSet.AddressSet internal _supportedCurrency;
    //================================
    //currency address
    mapping(address => D3xManagerType.Currency) internal _currency;

    //================================
    //pairNumber => Pair, pairNumber 随意设定
    mapping(uint16 => D3xManagerType.Pair) internal _pair;

    //pairCurrencyNumber => PairCurrency, 随意设定
    mapping(uint16 => D3xManagerType.PairCurrency) internal _pairCurrency;
    //activePaiCurrency list
    EnumerableSet.UintSet internal _activePairCurrency;

    //pairNumberCurrency => windowId => window
    mapping(uint16 => mapping(uint32 => D3xManagerType.PairCurrencyOIWindow)) internal _pairCurrencyOIWindow;

    //================================

    //trader => detail
    mapping(address => D3xManagerType.Person) internal _person;
    //================================
    //trader => currency  => detail
    mapping(address => mapping(address => D3xManagerType.PersonCurrency)) internal _personCurrency;

    //trader => pairCurrencyNumber => 单号  每个交易对只能开3个
    mapping(address => mapping(uint16 => EnumerableSet.UintSet)) internal _personTrade;
    mapping(address => mapping(uint16 => uint64[])) internal _personClosedTrade;

    //================================

    uint64 internal _currentTradeNumber;
    //tradeNumber => detail
    mapping(uint64 => D3xManagerType.Trade) internal _trade;
    //================================

    //================================
    //start from 1
    uint64 internal _currentOrderNumber;
    mapping(uint64 => D3xManagerType.Order) internal _order;

    //chainlink request id => order Id
    mapping(bytes32 => uint64) internal _chainlinkRequestIdToOrderId;

    //================================
    //price node, 在排除chainlink后 也就是喂价地址
    EnumerableSet.AddressSet internal _supportedSupplier;
    //supplier => currency => detail
    mapping(address => mapping(address => D3xManagerType.Supplier)) internal _supplier;

    //================================
    EnumerableSet.AddressSet internal _supportedLimitTrigger;
    //trigger => currency => detail
    mapping(address => mapping(address => D3xManagerType.Trigger)) internal _trigger;
}


