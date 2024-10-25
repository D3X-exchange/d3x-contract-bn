// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "../chainlinkClient/ChainlinkClientLogic.sol";
import "../twapPriceGetter/TWAPPriceGetterLogic.sol";
import "./D3xManagerInterface7.sol";

import "./D3xManagerType.sol";
import "contracts/dependant/helperLibrary/ConstantLibrary.sol";

contract D3xManagerLogic7 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
//ChainlinkClientLogic,
//TWAPPriceGetterLogic,
D3xManagerInterface7
{

//    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function getGlobalConfig() external view returns (D3xManagerType.GlobalConfig memory){
        return _getGlobalConfig();
    }

    /*function getSupportedCurrency() external view returns (address[] memory){
        return _supportedCurrency.values();
    }*/

    function getCurrency(address currency) external view returns (D3xManagerType.Currency memory){
        return _currency[currency];
    }

    /*function getCurrencyNested() external view returns (D3xManagerType.Currency[] memory){
        address[] memory currencies = _supportedCurrency.values();
        D3xManagerType.Currency[] memory ret = new  D3xManagerType.Currency[](currencies.length);

        for (uint256 i = 0; i < currencies.length; i++) {
            address currency = currencies[i];

            ret[i] = _currency[currency];
        }

        return ret;
    }*/

    function getPair(uint16 pairNumber) external view returns (D3xManagerType.Pair memory){
        return _pair[pairNumber];
    }

    function getPairCurrency(uint16 pairCurrencyNumber) external view returns (D3xManagerType.PairCurrency memory){
        return _pairCurrency[pairCurrencyNumber];
    }

    function getActivePairCurrency() external view returns (uint256[] memory){
        return _activePairCurrency.values();
    }

    /*function getActivePairCurrencyDetail(uint16 pairNumber) external view returns (D3xManagerType.ActivePairCurrencyDetail memory){
        return _activePairCurrencyList[pairNumber];
    }*/

    function getActivePairCurrencyNested(
    ) external view returns (
        D3xManagerType.GetActivePairCurrencyNestedResponse[] memory activePairCurrencyResponse
    ){

        uint256[] memory activePairCurrencyNumbers = _activePairCurrency.values();
        activePairCurrencyResponse = new  D3xManagerType.GetActivePairCurrencyNestedResponse[](activePairCurrencyNumbers.length);

        for (uint256 i = 0; i < activePairCurrencyNumbers.length; i ++) {
            uint16 pairCurrencyNumber = uint16(activePairCurrencyNumbers[i]);

            D3xManagerType.GetActivePairCurrencyNestedResponse memory ret = activePairCurrencyResponse[i];
            ret.pairCurrencyNumber = pairCurrencyNumber;
            ret.pairCurrency = _pairCurrency[pairCurrencyNumber];

            ret.pairNumber = ret.pairCurrency.pairNumber;
            ret.pair = _pair[ret.pairCurrency.pairNumber];

            ret.currency = ret.pairCurrency.currency;
            ret.configCurrency = _currency[ret.pairCurrency.currency];
            if(ret.configCurrency.vaultName != ConstantLibrary.ZERO_BYTES){
                ret.vaultAddress = ns().getSingle(ret.configCurrency.vaultName);
            }
        }
    }

    function getPairOI(uint16 pairCurrencyNumber, uint32 windowId) external view returns (D3xManagerType.PairCurrencyOIWindow memory){
        return _pairCurrencyOIWindow[pairCurrencyNumber][windowId];
    }

    function getPairWindowId(uint32 timestamp) external view returns (uint32){
        return _getWindowId(timestamp, _getGlobalConfig());
    }

    function getPerson(address who) external view returns (D3xManagerType.Person memory){
        return _person[who];
    }

    function getTrade(uint64 tradeNumber) external view returns (D3xManagerType.Trade memory){
        return _trade[tradeNumber];
    }

    function getPersonTrade(address who, uint16 pairCurrencyNumber) external view returns (uint256[] memory){
        return _personTrade[who][pairCurrencyNumber].values();
    }

    function getPersonClosedTrade(address who, uint16 pairCurrencyNumber) external view returns (uint64[] memory){
        return _personClosedTrade[who][pairCurrencyNumber];
    }

    function getPersonTradeNested(address who, uint16 pairCurrencyNumber) external view returns (
        D3xManagerType.Trade[] memory personTrade,
        D3xManagerType.Trade[] memory personClosedTrade
    ){

        {
            uint256[] memory personTradeIndexes = _personTrade[who][pairCurrencyNumber].values();
            personTrade = new D3xManagerType.Trade[](personTradeIndexes.length);

            for (uint256 i = 0; i < personTradeIndexes.length; i++) {
                uint64 index = uint64(personTradeIndexes[i]);
                personTrade[i] = _trade[index];
            }
        }

        {
            uint64[] memory personClosedTradeIndexes = _personClosedTrade[who][pairCurrencyNumber];
            personClosedTrade = new D3xManagerType.Trade[](personClosedTradeIndexes.length);

            for (uint256 i = 0; i < personClosedTradeIndexes.length; i++) {
                uint64 index = uint64(personClosedTradeIndexes[i]);
                personClosedTrade[i] = _trade[index];
            }
        }
    }

    function getOrder(uint64 orderNumber) external view returns (D3xManagerType.Order memory){
        return _order[orderNumber];
    }

    function getSupportedSupplier() external view returns (address[] memory){
        return _supportedSupplier.values();
    }

    function getSupportedLimitTrigger() external view returns (address[] memory){
        return _supportedLimitTrigger.values();
    }

    function getChainlinkRequestIdToOrderId(bytes32 requestId) external view returns (uint256){
        return _chainlinkRequestIdToOrderId[requestId];
    }

    /*function getOpeningOrClosingTrade() external view returns (uint256[] memory){
        return _openingOrClosingTrade.values();
    }*/

    function getPersonCurrency(address currency, address who) external view returns (D3xManagerType.PersonCurrency memory){
        return _personCurrency[who][currency];
    }

    function setGlobalConfig(D3xManagerType.GlobalConfig calldata input) external onlyOwner {
        _globalConfig[0] = input;
    }

    /*function setSupportedCurrency(address[] calldata adds, address[] calldata removes) external onlyOwner {
        for (uint256 i = 0; i < adds.length; i++) {
            _supportedCurrency.add(adds[i]);
        }

        for (uint256 i = 0; i < removes.length; i++) {
            _supportedCurrency.remove(removes[i]);
        }
    }*/

    function setCurrency(address currency, D3xManagerType.Currency calldata input) external onlyOwner {
        _currency[currency] = input;
    }

    function setPair(D3xManagerType.SetPairRequest[] calldata inputs) external onlyOwner {
        for (uint256 i = 0; i < inputs.length; i++) {

            D3xManagerType.SetPairRequest calldata input = inputs[i];
            D3xManagerType.Pair storage pair = _pair[input.pairNumber];

            pair.pairNumber = input.pairNumber;
            pair.from = input.from;
            pair.to = input.to;
            pair.maxDeviationFactorInExtraPoint = input.maxDeviationFactorInExtraPoint;
            pair.spreadFactorInExtraPoint = input.spreadFactorInExtraPoint;
            pair.feedPriceMultiplyDecimal = input.feedPriceMultiplyDecimal;
            pair.feedPriceDivideDecimal = input.feedPriceDivideDecimal;
            pair.feed1 = input.feed1;
            pair.feed2 = input.feed2;
            pair.accessType = input.accessType;
            pair.feedCalculation = input.feedCalculation;
            pair.pricePrintDecimal = input.pricePrintDecimal;
        }
    }

    function setPairCurrency(D3xManagerType.SetPairCurrencyRequest[] calldata inputs) external onlyOwner {
        for (uint256 i = 0; i < inputs.length; i++) {
            D3xManagerType.SetPairCurrencyRequest calldata input = inputs[i];

            D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[input.pairCurrencyNumber];

            pairCurrency.pairCurrencyNumber = input.pairCurrencyNumber;
            pairCurrency.pairNumber = input.pairNumber;
            pairCurrency.currency = input.currency;

            pairCurrency.minLeverage = input.minLeverage;
            pairCurrency.maxLeverage = input.maxLeverage;

            pairCurrency.openGovFeeFactorInExtraPoint = input.openGovFeeFactorInExtraPoint;
            pairCurrency.openStakingFeeFactorInExtraPoint = input.openStakingFeeFactorInExtraPoint;
            pairCurrency.openLimitTriggerFeeFactorInExtraPoint = input.openLimitTriggerFeeFactorInExtraPoint;

            pairCurrency.closeVaultFeeFactorInExtraPoint = input.closeVaultFeeFactorInExtraPoint;
            pairCurrency.closeStakingFeeFactorInExtraPoint = input.closeStakingFeeFactorInExtraPoint;

            pairCurrency.tradeFeeFactorInExtraPoint = input.tradeFeeFactorInExtraPoint;
            pairCurrency.oracleFeeFactorInExtraPoint = input.oracleFeeFactorInExtraPoint;
            pairCurrency.referralFeeFactorInExtraPoint = input.referralFeeFactorInExtraPoint;

            pairCurrency.minLeveragedPositionInCurrency = input.minLeveragedPositionInCurrency;
            pairCurrency.maxLeveragedPositionInCurrency = input.maxLeveragedPositionInCurrency;

        }
    }

    function setActivePairCurrency(
        uint16[] calldata addPairCurrency,
        uint16[] calldata removePairCurrency
    ) external onlyOwner {
        for (uint256 i = 0; i < addPairCurrency.length; i++) {
            uint16 add = addPairCurrency[i];

            _activePairCurrency.add(add);
        }

        for (uint256 i = 0; i < removePairCurrency.length; i++) {
            uint16 remove = removePairCurrency[i];

            _activePairCurrency.remove(remove);
        }
    }

    function setPairCurrencyDepth(D3xManagerType.SetPairCurrencyDepthRequest[] calldata input) external onlyOwner {

        for (uint256 i = 0; i < input.length; i++) {
            D3xManagerType.SetPairCurrencyDepthRequest calldata request = input[i];

            D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[request.pairCurrencyNumber];

            pairCurrency.onePercentDepthAbove = request.onePercentDepthAbove;
            pairCurrency.onePercentDepthBelow = request.onePercentDepthBelow;
        }
    }

    function setBorrowingFeeRate(D3xManagerType.SetBorrowingFeeRateRequest[] calldata input) external onlyOwner {

        for (uint256 i = 0; i < input.length; i++) {
            D3xManagerType.SetBorrowingFeeRateRequest calldata request = input[i];

            D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[request.pairCurrencyNumber];

            _setBorrowingFeeRate(pairCurrency, request.borrowingFeePerDayFactorInExtraPoint, request.maxOI);
        }
    }

    function setSupportedSupplier(address[] calldata node) external onlyOwner {
        while (0 < _supportedSupplier.length()) {
            _supportedSupplier.remove(_supportedSupplier.at(_supportedSupplier.length() - 1));
        }

        for (uint256 i = 0; i < node.length; i++) {
            _supportedSupplier.add(node[i]);
        }
    }

    function setSupportedLimitTrigger(address[] calldata trigger) external onlyOwner {
        while (0 < _supportedLimitTrigger.length()) {
            _supportedLimitTrigger.remove(_supportedLimitTrigger.at(_supportedLimitTrigger.length() - 1));
        }

        for (uint256 i = 0; i < trigger.length; i++) {
            _supportedLimitTrigger.add(trigger[i]);
        }
    }

    //{oracleTimestamp64|X|X|priceData64}
    //{oracleTimestamp64|low64|high64|open64}
    function packData(uint64 oracleTimestamp64, uint64 low, uint64 high, uint64 openOrPriceData64) external pure returns (uint256){
        uint256 s1 = uint256(oracleTimestamp64) << 192;
        uint256 s2 = uint256(low) << 128;
        uint256 s3 = uint256(high) << 64;
        uint256 s4 = uint256(openOrPriceData64);
        return s1 | s2 | s3 | s4;
    }
}
