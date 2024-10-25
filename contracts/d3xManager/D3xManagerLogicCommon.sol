// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "../dependant/ownable/OwnableLogic.sol";
import "../nameServiceRef/NameServiceRefLogic.sol";

import "./D3xManagerType.sol";
import "../dependant/proxy/Base.sol";
import "../dependant/helperLibrary/BytesLibrary.sol";
import "./D3xManagerEvent.sol";
import "hardhat/console.sol";

contract D3xManagerLogicCommon is Base, D3xManagerLayout,
OwnableLogic,
NameServiceRefLogic,
D3xManagerEvent
{

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    modifier onlyEOA() {
        require(tx.origin == msg.sender);
        _;
    }

    modifier preCheck(bool isNewTrade, bool isWriteFunction){
        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();
        if (isNewTrade && !globalConfig.enableNewTrade) {
            revert("701.NewTradeForbidden");
        }
        if (isWriteFunction && !globalConfig.enableWriteFunction) {
            revert("702.WriteFunctionForbidden");
        }
        _;
    }

    modifier onlySelf(){
        require(msg.sender == address(this), "703.onlySelf");
        _;
    }

    function _msgSender() internal view returns (address){
        return msg.sender;
    }


    function _setTradeState(D3xManagerType.Trade storage trade, uint8 newState) internal {
        uint8 oldState = trade.state;
        trade.state = newState;
        trade.lastStateUpdateTimestamp = _blockTimestamp();

        emit TradePivot(trade.tradeNumber, oldState, newState);
    }

    //计算动态价差
    //Dynamic Spread (%) = (Open interest {long/short} + New trade position size / 2) / 1% depth {above/below}.
    function _calcDynamicSpreadPriceImpact(
        D3xManagerType.GlobalConfig memory globalConfig,
        uint64 openPrice, // PRECISION  0的话就不用计算动态价差后的价格,只有价差百分比有意义
        D3xManagerType.PairCurrency memory pairCurrency,
        bool long,
        uint128 newOpenInterest // 1e18 (DAI)
    )
    internal
    view
    returns (
        uint24 priceImpactRateInExtraPoint, // PRECISION (%)  dynamic spread
        uint64 priceAfterImpact // PRECISION   Final opening price
    )
    {
        //btc/usd pair, onePercentDepthAbove 和 onePercentDepthBelow 是0,0  他走的是fixed spread
        //link/usd pair,  onePercentDepthAbove 和 onePercentDepthBelow 是815956,834918 他应该是走dynamic spread

        //Dynamic Spread (%) = (Open interest {long/short} + New trade position size / 2) / 1% depth {above/below}.

        //如果没有深度 那就是0, 那就是没有影响, 没有动态价差
        uint128 onePercentDepth = long ? pairCurrency.onePercentDepthAbove : pairCurrency.onePercentDepthBelow;
        if (onePercentDepth == 0) {
            priceImpactRateInExtraPoint = 0;
            priceAfterImpact = openPrice;
        } else {
            uint128 existOpenInterest = _getPriceImpactOI(globalConfig, pairCurrency.pairCurrencyNumber, long);

            //Dynamic Spread (%) = (Open interest {long/short} + New trade position size / 2) / 1% depth {above/below}.
            //0.0126% dynamic spread = (100,000 + 2,480 / 2) / 8,000,000 = 0.012655 注意 算出来的值自带百分号
            // priceImpactPercentIn10 = ((existOpenInterest + newOpenInterest / 2) * D3xManagerType.PRECISION) / onePercentDepth / 1e18;
            priceImpactRateInExtraPoint = _toUint24(
                (uint256(existOpenInterest) + newOpenInterest / 2)//分子
                * D3xManagerType.EXTEND_POINT//定点小数位数
                / onePercentDepth
            );//分母

            //Final opening price = _openPrice +/- _openPrice * Dynamic Spread
            //Final opening price = 3003.19 + (3003.19 * 0.0126 / 100) = 3003.57
            uint64 priceImpact = _toUint64(uint256(priceImpactRateInExtraPoint) * openPrice / D3xManagerType.EXTEND_POINT);
            priceAfterImpact = long ? openPrice + priceImpact : openPrice - priceImpact;
        }

    }

    //openInterest, 但是有滑动窗口
    function _getPriceImpactOI(
        D3xManagerType.GlobalConfig memory globalConfig,
        uint16 pairCurrencyNumber,
        bool long
    ) internal view returns (uint128 activeOI) {
        activeOI = 0;

        uint32 currentWindowId = _getWindowId(_blockTimestamp(), globalConfig);
        uint32 earliestWindowId = _getEarliestActiveWindowId(currentWindowId, globalConfig.oiWindowsCount);

        for (uint32 i = earliestWindowId; i <= currentWindowId; i++) {
            D3xManagerType.PairCurrencyOIWindow memory pairCurrencyOIWindow = _pairCurrencyOIWindow[pairCurrencyNumber][i];
            activeOI += long ? pairCurrencyOIWindow.long : pairCurrencyOIWindow.short;
        }
    }

    //====================

    function _calcLiquidationPrice(
        uint64 _openPrice_,   // D3xPairType.PRECISION
        bool _long_,
        uint128 _position_,  // 1e18 (DAI)
        uint8 _leverage_,
        uint128 _borrowingFee_ // 1e18 (DAI)
    ) public pure returns (uint64 liqPrice){ // D3xPairType.PRECISION
        /*
        // 当前可用本金=本金*0.9[清仓率] - 租借费  (如果是long,如果为负数,那么其实清算的价格都需要比开单价来的高了)
        // 当前可用本金的比例 = 当前可用本金/本金
        // 清算容忍delta=可用本金对总价格的比例=开单价格*当前可用本金的比例/杠杆
        int liqPriceDistance = int(_openPrice_) * (
            int(_collateral_ * D3xPairType.LIQ_THRESHOLD_P / 100)//uint256 constant LIQ_THRESHOLD_P = 90;
            - int(_rolloverFee_) - _fundingFee_
        ) / int(_collateral_) / int(_leverage_);

        int liqPrice = _long_ ?
            //如果是long,那么亏损的delta是代表价格下跌
            int(_openPrice_) - liqPriceDistance :
            int(_openPrice_) + liqPriceDistance;

        //如果short, 可能随着租借费的上涨  价格到0都不够清算的
        return liqPrice > 0 ? uint(liqPrice) : 0;

        //租借费越来越高,到后面可能盈利了都不够付费的

        //最大亏损率(可能为负,必须盈利才能够支付租借费)= LIQ_THRESHOLD_P(90)- 租借费占本金百分比
        //最大亏损率 = 90% - _borrowingFee_/_position_ = (0.9*_position_ - _borrowingFee_)/_position_

        */

        bool deltaPlus = true;
        uint128 safe = _toUint128(uint256(_position_) * D3xManagerType.LIQ_THRESHOLD_P / D3xManagerType.PERCENT);
        if (safe < _borrowingFee_) {
            //本金都不够租借费了
            deltaPlus = false;
        }
        uint64 delta = _toUint64(
            (
                deltaPlus ?
                    uint256(safe) - _borrowingFee_ :
                    uint256(_borrowingFee_) - safe
            ) * _openPrice_
            / _position_
            / _leverage_
        );

        //liqPrice = 0;
        if (_long_) {
            //liqPrice = _openPrice_ - delta;
            if (deltaPlus) {
                //其实是不会不够减的
                //liqPrice = _openPrice_ - delta;
                if (delta <= _openPrice_) {
                    liqPrice = _openPrice_ - delta;
                } else {
                    liqPrice = 0;
                }
            } else {
                liqPrice = _openPrice_ + delta;
            }
        } else {
            //liqPrice =_openPrice_ + delta;
            if (deltaPlus) {
                liqPrice = _openPrice_ + delta;
            } else {
                //安全金都不够了 需要拿利润来填租借费了
                //liqPrice =_openPrice_ - delta;
                if (delta <= _openPrice_) {
                    liqPrice = _openPrice_ - delta;
                } else {
                    //利润越来越不够  为了保证利润 价格也是越来越低  直到0  强制爆仓
                    liqPrice = 0;
                }
            }
        }
        return liqPrice;
    }

    //=====================================================================

    function _calcTradeFee(
    //D3xManagerType.Pair storage pair,
    //D3xManagerType.PairCurrency memory pairCurrency,
        uint128 leveragedPositionSize,
        uint24 tradeFeeFactorInExtraPoint
    ) internal pure returns (uint128) {
        // 3. Calculate Market/Limit fee
        //btc 0.0200000000 为什么是0.02??
        //开单的时候 0.004% -> Market/Limit 关单的时候 0.004% -> Market/Limit  开单总共0.08 关单总共0.08
        return _toUint128(
            uint256(leveragedPositionSize) * /*pairCurrency.*/tradeFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }

    //=====================================================================

    //no trade for per-trade-update because trade will not update accFee twice
    //do remember update pair.longOI
    function _updateAccFee(
        D3xManagerType.PairCurrency storage pairCurrency
    ) internal {
        (
            pairCurrency.accFeeLongStore,
            pairCurrency.accFeeShortStore
        ) = _accFeePerPosition(//_updateAccFee
            pairCurrency//do a copy from storage to memory
        );
        pairCurrency.accFeeLastUpdated = _blockTimestamp();
    }

    function _setBorrowingFeeRate(
        D3xManagerType.PairCurrency storage pairCurrency,
        uint24 borrowingFeePerDayFactorInExtraPoint,
        uint128 maxOI
    ) internal {
        _updateAccFee(pairCurrency);//_setBorrowingFeeRate
        pairCurrency.borrowingFeePerDayFactorInExtraPoint = borrowingFeePerDayFactorInExtraPoint;
        pairCurrency.maxOI = maxOI;
    }

    function _accFeePerPosition(
        D3xManagerType.PairCurrency memory pairCurrency
    )
    internal
    view
    returns (
        uint128 newAccFeeLongStore,
        uint128 newAccFeeShortStore
    ){
        //很罕见, 如果在开单关单时触发,会导致revert,最后order关闭了,但是callback+process没有正确处理
        require(pairCurrency.accFeeLastUpdated <= _blockTimestamp(), "704.time machine");

        if (0 == pairCurrency.maxOI) {
            return (0, 0);
        }

        (
            uint256 borrowingFeeRatePerDayForLong,
            uint256 borrowingFeeRatePerDayForShort
        ) = _borrowingFeeRatePerDay(pairCurrency);

        //具体的accFeeLong accFeeShort的变更量
        uint128 delta = _toUint128(
            uint256(//*时间差
                _blockTimestamp() -
                pairCurrency.accFeeLastUpdated//如果已经调用过update 那么这里算出来就是0
            ) *
            (borrowingFeeRatePerDayForLong == 0 ? borrowingFeeRatePerDayForShort : borrowingFeeRatePerDayForLong) /
            1 days
        );

        //require(delta <= type(uint64).max, "OVERFLOW");

        newAccFeeLongStore = borrowingFeeRatePerDayForLong == 0 ? pairCurrency.accFeeLongStore : pairCurrency.accFeeLongStore + delta;
        newAccFeeShortStore = borrowingFeeRatePerDayForLong == 0 ? pairCurrency.accFeeShortStore + delta : pairCurrency.accFeeShortStore;
        return (newAccFeeLongStore, newAccFeeShortStore);
    }

    function _borrowingFeeRatePerDay(D3xManagerType.PairCurrency memory pairCurrency) internal view returns (
        uint256 borrowingFeeRatePerDayForLong,
        uint256 borrowingFeeRatePerDayForShort
    ){

        D3xManagerType.Currency memory currency = _currency[pairCurrency.currency];

        bool moreShorts = pairCurrency.longOI < pairCurrency.shortOI;
        //多和空之间的gap
        //uint128 netOI = moreShorts ? pairCurrency.shortOI - pairCurrency.longOI : pairCurrency.longOI - pairCurrency.shortOI;

        //多和空之前的ratio
        //保留6位小数,最多不超过10
        uint128 rateInExtendPoint = 0;
        if (pairCurrency.shortOI == 0 && pairCurrency.longOI == 0) {
            //空局, 保持0
            rateInExtendPoint = 0;
        } else if (
            (pairCurrency.shortOI == 0 && pairCurrency.longOI != 0) ||
            (pairCurrency.shortOI != 0 && pairCurrency.longOI == 0)
        ) {
            //单边,无脑设定为10
            rateInExtendPoint = 10 * D3xManagerType.EXTEND_POINT;
        } else if (moreShorts) {
            rateInExtendPoint = pairCurrency.shortOI * D3xManagerType.EXTEND_POINT / pairCurrency.longOI;
        } else {
            rateInExtendPoint = pairCurrency.longOI * D3xManagerType.EXTEND_POINT / pairCurrency.shortOI;
        }
        if (10 * D3xManagerType.EXTEND_POINT < rateInExtendPoint) {
            rateInExtendPoint = 10 * D3xManagerType.EXTEND_POINT;
        }

        uint256 borrowingFeeRatePerDay = uint256(10 ** currency.decimal) *//unit
                        pairCurrency.borrowingFeePerDayFactorInExtraPoint * //30,0.00003 in extent point
                    rateInExtendPoint / //10_000000 in extent point
                        D3xManagerType.EXTEND_POINT /
                        D3xManagerType.EXTEND_POINT;
        return moreShorts ? (uint256(0), borrowingFeeRatePerDay) : (borrowingFeeRatePerDay, uint256(0));
    }

    function _calcBorrowingFee(D3xManagerType.Trade memory trade) internal view returns (uint128){
        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[trade.pairCurrencyNumber];
        D3xManagerType.Currency memory currency = _currency[trade.currency];

        (uint128 newAccFeeLongStore,uint128 newAccFeeShortStore) = _accFeePerPosition(pairCurrency);//_calcBorrowingFee

        uint128 tempNewStore = trade.long ? newAccFeeLongStore : newAccFeeShortStore;
        //trade.accFeePaidForPair 是开单时记录的
        uint128 deltaStore = tempNewStore - trade.accFeePaid;
        //return trade.openPositionInCurrency * trade.leverage * temp / 1e10; // 1e18 (DAI)

        return _toUint128(
            uint256(trade.openPositionInCurrency) * trade.leverage * deltaStore / (10 ** currency.decimal)
        );
    }

    //========================

    function _calcTpSlPrice(
        uint64 openPrice,
        bool long,
        uint8 leverage,
        uint16 percent /*900*/,
        bool tp
    ) internal pure returns (uint64){

        uint64 price = openPrice;

        uint64 delta = _toUint64(
            uint256(openPrice) * percent / leverage / D3xManagerType.PERCENT
        );

        if (tp) {
            if (long) {
                price += delta;
            } else {
                if (delta <= price) {
                    price -= delta;
                } else {
                    price = 0;
                }
            }
        } else {
            if (long) {
                if (delta <= price) {
                    price -= delta;
                } else {
                    price = 0;
                }
            } else {
                price += delta;
            }
        }

        return price;
    }

    //====================

    function _getWindowId(uint32 timestamp, D3xManagerType.GlobalConfig memory globalConfig) internal pure returns (uint32) {
        return (timestamp - globalConfig.oiStartTimestamp) / globalConfig.oiWindowsDuration;
    }

    function _getEarliestActiveWindowId(uint32 currentWindowId, uint8 windowsCount) internal pure returns (uint32) {
        uint8 windowNegativeDelta = windowsCount - 1; // -1 because we include current window
        return windowNegativeDelta < currentWindowId ? currentWindowId - windowNegativeDelta : 0;
    }

    //====================

    //normal return(not revert or require), use 'return' instead of 'revert'
    //but the returnData is concatenated with MIMIC_ERROR
    //to quick eject INTERNAL_ERROR
    function _mimicErrorReturn(bool condition, string memory reason) internal pure {
        if (!condition) {
            returnAsm(false, BytesLibrary.concat(abi.encodePacked(D3xManagerType.MIMIC_ERROR), bytes(reason)));
        }
    }

    //if there is a 'revert' of invocation, just revert it!!!!
    function _invokeAndCheckMimicError(
        address targetAddress,
        bytes memory data,
        uint256 value
    )
    internal
    returns (
        bool isMimicError,
        bytes memory mimicErrorData,
        bytes memory returnData//better to only return error msg, return none normal function return data!!!
    ){
        (bool success, bytes memory _returnData_) = targetAddress.call{value: value}(data);

        if (success) {
            //无报错
            if (
                32 <= _returnData_.length &&
                BytesLibrary.toBytes32(_returnData_, 0) == D3xManagerType.MIMIC_ERROR
            ) {
                //内部错误
                isMimicError = true;
                returnData = bytes("");

                mimicErrorData = BytesLibrary.slice(_returnData_, 32, _returnData_.length - 32);

            } else {
                //正常返回
                isMimicError = false;
                mimicErrorData = bytes("");
                returnData = _returnData_;
            }
        } else {
            //revert了,直接抛出

            //for lint
            isMimicError = false;
            mimicErrorData = bytes("");
            returnData = bytes("");

            returnAsm(true, _returnData_);
        }
    }

    //============================


    function _uint256ToInt256(uint256 input) internal pure returns (int256){
        //<= 2**255-1
        _mimicErrorReturn(input < 2 ** 255, "705.uint to int fails");
        return int256(input);
    }

    function _int256ToUint256(int256 input) internal pure returns (uint256){
        _mimicErrorReturn(0 <= input, "706.int to uint fails");
        return uint256(input);
    }

    function _toUint24(uint256 input) internal pure returns (uint24){
        _mimicErrorReturn(input <= type(uint24).max, "707.to uint24 fails");
        return uint24(input);
    }

    function _toUint64(uint256 input) internal pure returns (uint64){
        _mimicErrorReturn(input <= type(uint64).max, "708.to uint64 fails");
        return uint64(input);
    }

    function _toUint128(uint256 input) internal pure returns (uint128){
        _mimicErrorReturn(input <= type(uint128).max, "709.to uint128 fails");
        return uint128(input);
    }

    //==============================================

    function _getGlobalConfig() internal view returns (
        D3xManagerType.GlobalConfig storage
    ){
        return _globalConfig[0];
    }

    function _getCurrency(address currency) internal view returns (
        D3xManagerType.Currency storage
    ){
        return _currency[currency];
    }


    function _getPair(uint16 pairNumber) internal view returns (
        D3xManagerType.Pair storage
    ){
        return _pair[pairNumber];
    }

    function _getPairCurrency(uint16 pairCurrencyNumber) internal view returns (
        D3xManagerType.PairCurrency storage
    ){
        return _pairCurrency[pairCurrencyNumber];
    }

    function _getTrade(uint64 tradeNumber) internal view returns (
        D3xManagerType.Trade storage
    ){
        return _trade[tradeNumber];
    }

    function _getOrder(uint64 orderNumber) internal view returns (
        D3xManagerType.Order storage
    ){
        return _order[orderNumber];
    }

    function _blockTimestamp() internal view returns (uint32){
        return uint32(block.timestamp);
    }

    function sysPrintUint256ToHex(uint256 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintBytesToHex(bytes memory input) internal pure returns (string memory){
        bytes memory ret = new bytes(input.length * 2);
        bytes memory alphabet = "0123456789abcdef";
        for (uint256 i = 0; i < input.length; i++) {
            bytes32 t = bytes32(input[i]);
            bytes32 tt = t >> 31 * 8;
            uint256 b = uint256(tt);
            uint256 high = b / 0x10;
            uint256 low = b % 0x10;
            bytes1 highAscii = alphabet[high];
            bytes1 lowAscii = alphabet[low];
            ret[2 * i] = highAscii;
            ret[2 * i + 1] = lowAscii;
        }
        return string(ret);
    }
}
