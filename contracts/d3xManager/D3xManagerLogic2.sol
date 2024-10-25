// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "./D3xManagerInterface2.sol";

import "./D3xManagerType.sol";
import "./D3xManagerInterface1.sol";
import 'contracts/dependant/helperLibrary/FundLibrary.sol';
import "contracts/dependant/helperLibrary/ConstantLibrary.sol";
import "hardhat/console.sol";

//openTradeMarket closeTradeMarket
//openTradeLimit cancelTradeLimit triggerLimitOrder
//_openTradeCheck _addNewTrade
contract D3xManagerLogic2 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
//ChainlinkClientLogic,
//TWAPPriceGetterLogic,
D3xManagerInterface2
{

//    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    //用市价单开仓
    function openTradeMarket(
        D3xManagerType.OpenTradeRequest memory request//do a copy from calldata to memory
    )
    external
    preCheck(true/*isNewTrade*/, true/*isWriteFunction*/)
    onlyEOA {

        address who = _msgSender();

        address currency = _openTradeCheck(request, false, who);

        //take fund
        {
            //暂时收到TradeAnyMix内
            FundLibrary._fundFromSBToSBOrSafetyBox(
                currency,
                who,
                openTradeAnyMix(),
                request.desiredPositionInCurrency
            );
        }

        //1 存储开单请求
        (
            D3xManagerType.Trade storage trade,
            uint64 tradeNumber
        ) = _addNewTrade(
            request,
            D3xManagerType.TRADE_STATE_MARKET_OPENING,
            who
        );

        uint32 openingTimestamp = _blockTimestamp();
        trade.openingTimestamp = openingTimestamp;

        //2 请求price order
        D3xManagerInterface1(address(this)).requestPriceOrder(
            tradeNumber,
            D3xManagerType.ORDER_TYPE_MARKET_OPEN,
            openingTimestamp,
            0,//fromTimestamp
            0//toTimestamp
        );

    }

    //手动将仓位关闭,只能是已经开启的仓位
    function closeTradeMarket(
        uint64 tradeNumber
    ) external
    preCheck(true/*isNewTrade*/, true/*isWriteFunction*/)
    onlyEOA {

        //只读取1次必要的数据
        D3xManagerType.Trade memory trade = _trade[tradeNumber];

        require(trade.state == D3xManagerType.TRADE_STATE_LIVE, "101.wrong trade state");
        require(trade.who == _msgSender(), "102.only trade.who for now");

        uint32 closingTimestamp = _blockTimestamp();
        {
            D3xManagerType.Trade storage tradeStorage = _trade[tradeNumber];
            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_MARKET_CLOSING);
            tradeStorage.closingTimestamp = closingTimestamp;
        }

        //这里其实是关闭仓位
        D3xManagerInterface1(address(this)).requestPriceOrder(
            tradeNumber,
            D3xManagerType.ORDER_TYPE_MARKET_CLOSE,
            //trade.initialPositionPriceInD3x * trade.d3xPriceInUsdt * trade.leverage / D3xManagerType.PRECISION,
            closingTimestamp,//tradeLastActionUpdateTimestamp
            0,//fromTimestamp
            0//toTimestamp
        );
    }

    //====================

    function openTradeLimit(
        D3xManagerType.OpenTradeRequest memory request
    )
    external
    preCheck(true/*isNewTrade*/, true/*isWriteFunction*/)
    onlyEOA {

        address who = _msgSender();
        address currency = _openTradeCheck(request, true, who);

        //take fund
        {
            FundLibrary._fundFromSBToSBOrSafetyBox(
                currency,
                who,
                openTradeAnyMix(),
                request.desiredPositionInCurrency
            );
        }

        (
            D3xManagerType.Trade storage trade,
        /*uint64 tradeNumber*/
        ) = _addNewTrade(
            request,
            D3xManagerType.TRADE_STATE_LIMIT_PENDING,
            who
        );
        trade.limitPendingTimestamp = _blockTimestamp();
    }

    //关闭等待撮合的Limit单
    function cancelTradeLimit(
        uint64 tradeNumber
    )
    external
    preCheck(false/*isNewTrade*/, true/*isWriteFunction*/)
    onlyEOA {

        address who = _msgSender();

        D3xManagerType.Trade memory trade = _trade[tradeNumber];

        require(trade.state == D3xManagerType.TRADE_STATE_LIMIT_PENDING, "201.wrong trade state");
        require(trade.who == who, "202.only trade.who for now");

        //return fund
        {
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(trade.currency, openTradeAnyMix(), who, trade.desiredPositionInCurrency);
        }

        {
            D3xManagerType.Trade storage tradeStorage = _trade[tradeNumber];
            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_LIMIT_CANCELLED);
            tradeStorage.closeTimestamp = _blockTimestamp();
            tradeStorage.closePrice = 0;
        }


        _personTrade[trade.who][trade.pairCurrencyNumber].remove(tradeNumber);
        _personClosedTrade[trade.who][trade.pairCurrencyNumber].push(tradeNumber);
    }

    //limit单有4种触发,方便用一个方法做统一入口
    //limit的开单
    //trader的tp关单
    //trader的sl关单
    //trader的liq关单
    function triggerLimitOrder(
        D3xManagerType.LimitTradeTriggerRequest[] memory params
    ) external {

        require(_supportedLimitTrigger.contains(_msgSender()), "301.only limit triggers");

        for (uint256 i = 0; i < params.length;) {

            D3xManagerType.LimitTradeTriggerRequest memory param = params[i];

            uint64 tradeNumber = param.tradeNumber;

            D3xManagerType.Trade memory trade = _trade[tradeNumber];

            require(trade.tradeNumber == tradeNumber, "302.wrong trade number");

            if (param.triggerType == D3xManagerType.TRADE_STATE_LIMIT_OPENING) {
                _triggerLimitOrderOpen(tradeNumber, trade, param.fromTimestamp, param.toTimestamp);
            } else if (param.triggerType == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING) {
                _triggerLimitOrderTp(tradeNumber, trade, param.fromTimestamp, param.toTimestamp);
            } else if (param.triggerType == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING) {
                _triggerLimitOrderSl(tradeNumber, trade, param.fromTimestamp, param.toTimestamp);
            } else if (param.triggerType == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING) {
                _triggerLimitOrderLiq(tradeNumber, trade, param.fromTimestamp, param.toTimestamp);
            } else {
                revert("303.wrong trigger type");
            }

            unchecked{i++;}
        }
    }

    function _triggerLimitOrderOpen(
        uint64 tradeNumber,
        D3xManagerType.Trade memory trade,
        uint32 fromTimestamp,
        uint32 toTimestamp
    ) internal {

        //check
        require(trade.state == D3xManagerType.TRADE_STATE_LIMIT_PENDING, "304.wrong trade state");

        uint128 desiredLeveragedPosition = trade.desiredPositionInCurrency * trade.leverage;

        uint16 pairCurrencyNumber = trade.pairCurrencyNumber;
        D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[pairCurrencyNumber];

        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();

        //计算当前因为OpenOI导致的动态价差,暂时不考虑价格,仅用于计算安全性
        (uint24 priceImpactRateInExtraPoint,) = _calcDynamicSpreadPriceImpact(
            globalConfig,
            0,//设定为0,只需要读取价差百分比,不需要计算实际的价差 价差=价格*价差百分比
            pairCurrency,
            trade.long,
            desiredLeveragedPosition
        );

        //require(priceImpactPercentIn10 * trade.leverage <= _getGlobalConfig().maxNegativePnlOnOpenIn10, "305.price impact too high");
        require(priceImpactRateInExtraPoint * trade.leverage <= globalConfig.maxNegativePnlOnOpenWith10 * D3xManagerType.PRECISION, "305.price impact too high");

        {
            D3xManagerType.Trade storage tradeStorage = _trade[tradeNumber];

            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_LIMIT_OPENING);
            tradeStorage.openingTimestamp = _blockTimestamp();

            tradeStorage.openLimitTrigger = _msgSender();
        }

        //请求oracle
        D3xManagerInterface1(address(this)).requestPriceOrder(
            tradeNumber,
            D3xManagerType.ORDER_TYPE_LIMIT_OPEN,
            trade.limitPendingTimestamp,//自下单之后
            fromTimestamp,
            toTimestamp
        );
    }

    function _triggerLimitOrderTp(
        uint64 tradeNumber,
        D3xManagerType.Trade memory trade,
        uint32 fromTimestamp,
        uint32 toTimestamp
    ) internal {

        //check
        require(trade.state == D3xManagerType.TRADE_STATE_LIVE, "306.wrong trade state");

        _setTradeState(_trade[tradeNumber], D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING);

        //请求oracle
        D3xManagerInterface1(address(this)).requestPriceOrder(
            tradeNumber,
            D3xManagerType.ORDER_TYPE_LIMIT_CLOSE,
            trade.tpTimestamp,
            fromTimestamp,
            toTimestamp
        );
    }


    function _triggerLimitOrderSl(
        uint64 tradeNumber,
        D3xManagerType.Trade memory trade,
        uint32 fromTimestamp,
        uint32 toTimestamp
    ) internal {

        //check
        require(trade.state == D3xManagerType.TRADE_STATE_LIVE, "307.wrong trade state");
        require(trade.isSlSet, "308.SL is not set");

        _setTradeState(_trade[tradeNumber], D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING);

        //请求oracle
        D3xManagerInterface1(address(this)).requestPriceOrder(
            trade.tradeNumber,
            D3xManagerType.ORDER_TYPE_LIMIT_CLOSE,
            trade.slTimestamp,
            fromTimestamp,
            toTimestamp
        );
    }


    function _triggerLimitOrderLiq(
        uint64 tradeNumber,
        D3xManagerType.Trade memory trade,
        uint32 fromTimestamp,
        uint32 toTimestamp
    ) internal {

        //check
        require(trade.state == D3xManagerType.TRADE_STATE_LIVE, "309.wrong trade state");

        //判断是否满足liq的条件
        if (trade.isSlSet) {
            //如果设定了sl

            //开单时计算的清仓价
            //暂时不知道如何计算
            uint128 borrowingFee = _calcBorrowingFee(trade);//_triggerLimitOrderLiq

            uint64 liqPrice = _calcLiquidationPrice(
                trade.openPrice,
                trade.long,
                trade.openPositionInCurrency,
                trade.leverage,
                borrowingFee
            );

            // If liq price not closer than SL, turn order into a SL order
            //long,  开单时清仓价格 < 止损价,  那么清仓单=>止损单      这似乎是早期代码的问题
            //链下认为该清仓了,但是清仓价格低于止损价格,属于链下计算清仓价格有问题,只要触发止损就可以了
            if (
                trade.isSlSet &&
                (
                    (trade.long && liqPrice <= trade.sl) ||
                    (!trade.long && trade.sl <= liqPrice)
                )
            ) {
                //转为止损单
                _triggerLimitOrderSl(tradeNumber, trade, fromTimestamp, toTimestamp);
                return;
            }
        }

        _setTradeState(_trade[tradeNumber], D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING);

        //请求oracle
        D3xManagerInterface1(address(this)).requestPriceOrder(
            tradeNumber,
            D3xManagerType.ORDER_TYPE_LIMIT_CLOSE,
            trade.createTimestamp,
            fromTimestamp,
            toTimestamp
        );
    }

    //===========================
    //不检查静态价差和静态价差
    function _openTradeCheck(
        D3xManagerType.OpenTradeRequest memory request,
        bool isLimit,
        address who
    ) internal view returns (address) {

        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();

        require(_activePairCurrency.contains(request.pairCurrencyNumber), "115.pair currency is not activated");

        //sload all
        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[request.pairCurrencyNumber];

        //检查pairCurrency
        //require(pairCurrency.pairCurrencyNumber != 0, "103.unsupported currency");
        //检查交易对
        //require(_pair[pairCurrency.pairNumber].from != ConstantLibrary.ZERO_BYTES, "104.unsupported pair");

        //D3xManagerType.Pair storage pair = _pair[request.pairNumber];
        uint128 leveragedPositionInCurrency = request.desiredPositionInCurrency * request.leverage;

        //=============个人检查=============
        //1个交易对 最多只有3个单子
        require(
            _personTrade[who][request.pairCurrencyNumber].length() < globalConfig.maxTradePerPairCurrency,
            "105.too much trade for the given pair"
        );

        //=============参数检查=============
        //require(pairCurrency.minLeveragedPositionInCurrency != 0, "106.pairCurrency wrong");
        require(request.leverage != 0, "107.leverage should never be 0");
        require(pairCurrency.minLeverage <= request.leverage, "108.minLeverage");
        require(request.leverage <= pairCurrency.maxLeverage, "109.maxLeverage");

        require(0 < request.desiredOpenPrice, "112.desiredOpenPrice should not be 0 for now");
        require(uint256(request.desiredOpenPrice) * request.slippageFactorInExtraPoint / D3xManagerType.EXTEND_POINT < type(uint64).max, "110.price*slippage");
        require(request.slippageFactorInExtraPoint < D3xManagerType.EXTEND_POINT, "111.slippageFactorInExtraPoint");


        require(
            leveragedPositionInCurrency +
            (
                request.long ?
                    pairCurrency.longOI :
                    pairCurrency.shortOI
            )
            <= pairCurrency.maxOI,
            "113.too much currency for pair"
        );

        require(pairCurrency.minLeveragedPositionInCurrency <= leveragedPositionInCurrency, "114.pair minLeveragedPosition");
        require(leveragedPositionInCurrency <= pairCurrency.maxLeveragedPositionInCurrency, "115.pair maxLeveragedPosition");

        require(
        //服务器处理时会强制设定成900%
            request.desiredTp == 0 ||
            (
                request.long ?
                    request.desiredOpenPrice < request.desiredTp :
                    request.desiredTp < request.desiredOpenPrice
            ),
            "116.wrong tp"
        );
        require(
            !request.desiredIsSlSet ||
            (//sl被设定
                request.long ?
                    request.desiredSl < request.desiredOpenPrice :
                    request.desiredOpenPrice < request.desiredSl

            ),
            "117.wrong sl"
        );

        //========Dynamic Spread (%)
        //不在乎开仓时的价格,只在乎价差所影响的百分比
        (uint24 priceImpactRateInExtraPoint,) = _calcDynamicSpreadPriceImpact(
            globalConfig,
            0,//不计算受到动态价差后的实际价格
            pairCurrency,
            request.long,
            leveragedPositionInCurrency
        );

        require(priceImpactRateInExtraPoint * request.leverage <= globalConfig.maxNegativePnlOnOpenWith10 * D3xManagerType.PRECISION, "118.price impact too high");

        if (isLimit) {
            require(
                request.tradeType == D3xManagerType.TRADER_TYPE_LIMIT ||
                request.tradeType == D3xManagerType.TRADER_TYPE_STOP_LIMIT,
                "119.trade type error"
            );
        } else {
            require(
                request.tradeType == D3xManagerType.TRADER_TYPE_MARKET, "120.trade type error");
        }

        return pairCurrency.currency;
    }

    function _addNewTrade(
        D3xManagerType.OpenTradeRequest memory request,
        uint8 tradeState,
        address who
    ) internal returns (
        D3xManagerType.Trade storage,
        uint64 tradeNumber
    ){

        uint64 currentTradeNumber = _currentTradeNumber;
        currentTradeNumber++;
        _currentTradeNumber = currentTradeNumber;
        tradeNumber = currentTradeNumber;

        //用storage就读2个变量
        D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[request.pairCurrencyNumber];

        //应该有asm把前段的数据pack起来然后单独存入,不过差别不大
        _trade[tradeNumber] = D3xManagerType.Trade({
            tradeNumber: tradeNumber,
            who: who,
            state: D3xManagerType.TRADE_STATE_EMPTY,
            tradeType: request.tradeType,
            pairCurrencyNumber: request.pairCurrencyNumber,

            pairNumber: pairCurrency.pairNumber,
            long: request.long,
            leverage: request.leverage,
            currency: pairCurrency.currency,
            orderNumber: 0,
            lastStateUpdateTimestamp: _blockTimestamp(),
            slippageFactorInExtraPoint: request.slippageFactorInExtraPoint,
            desiredTp: request.desiredTp,
            desiredSl: request.desiredSl,
            desiredIsSlSet: request.desiredIsSlSet,
            desiredOpenPrice: request.desiredOpenPrice,

            desiredPositionInCurrency: request.desiredPositionInCurrency,

            openPositionInCurrency: 0,
            openPrice: 0,
            openD3xPriceInCurrency: 0,
            accFeePaid: 0,
            accFeePaidTimestamp: 0,
            openLimitTrigger: address(0),
            pairCurrencyOIWindowId: 0,
            reserved32: 0,
            tp: 0,
            sl: 0,
            isSlSet: false,
            closeTimestamp: 0,
            closePrice: 0,
            reserved24: 0,
            cancelReason: "",
            closeReturnPositionInCurrency: 0,
            openGovFee: 0,
            openStakingFee: 0,
            openTradeFee: 0,
            openLimitTriggerFee: 0,
            openOracleFee: 0,

            closeTradeFee: 0,
            closeVaultFee: 0,
            closeStakingFee: 0,
            closeOracleFee: 0,
            borrowingFee: 0,
            limitPendingTimestamp: 0,
            openingTimestamp: 0,
            createTimestamp: 0,
            tpTimestamp: 0,
            slTimestamp: 0,
            closingTimestamp: 0,
            reserved192: 0
        });

        /*trade.tradeNumber = tradeNumber;
        trade.who = who;
        //trade.state = tradeState;
        _setTradeState(trade, tradeState);
        trade.tradeType = request.tradeType;
        trade.pairNumber = request.pairNumber;
        trade.long = request.long;
        trade.leverage = request.leverage;
        trade.currency = request.currency;
        trade.orderNumber = 0;
        trade.lastStateUpdateTimestamp = _blockTimestamp();
        trade.slippageFactorInExtraPoint = request.slippageFactorInExtraPoint;

        trade.desiredPositionInCurrency = request.desiredPositionInCurrency;
        trade.desiredTp = request.desiredTp;
        trade.desiredSl = request.desiredSl;
        trade.desiredIsSlSet = request.desiredIsSlSet;
        trade.desiredOpenPrice = request.desiredOpenPrice;*/


        D3xManagerType.Trade storage trade = _trade[tradeNumber];
        _setTradeState(trade, tradeState);

        _personTrade[who][request.pairCurrencyNumber].add(tradeNumber);

        return (trade, tradeNumber);
    }

}
