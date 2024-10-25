// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "../chainlinkClient/ChainlinkClientLogic.sol";
import "../twapPriceGetter/TWAPPriceGetterLogic.sol";
import "./D3xManagerInterface5.sol";

import "./D3xManagerType.sol";
import "./D3xManagerInterface1.sol";
import "../dependant/helperLibrary/FundLibrary.sol";

//isTradeTimeout
//openTradeMarketTimeout closeTradeMarketTimeout
//triggerTradeLimitOpeningTimeout triggerTradeLimitTpSlLiqClosingTimeout
contract D3xManagerLogic5 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
//ChainlinkClientLogic,
//TWAPPriceGetterLogic,
D3xManagerInterface5
{

//    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    //只要是opening或者closing都是timeout
    function isTradeTimeout(
        uint64 tradeNumber
    ) external view returns (bool){

        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();
        D3xManagerType.Trade memory trade = _trade[tradeNumber];
        D3xManagerType.Order memory order = _order[trade.orderNumber];

        if (
            (
                trade.state == D3xManagerType.TRADE_STATE_MARKET_OPENING ||
                trade.state == D3xManagerType.TRADE_STATE_LIMIT_OPENING ||
                trade.state == D3xManagerType.TRADE_STATE_MARKET_CLOSING ||
                trade.state == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING ||
                trade.state == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING ||
                trade.state == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING
            ) &&
            (
                (
                //order已经关闭,可能是滑点超了,这通常会被自动关闭到cancelled状态,或者退回到live状态
                //但也不排除callback和process里有revert或者panic,导致了没有关闭成功
                    trade.orderNumber == 0
                )
                ||
                (
                //trade.orderNumber != 0 &&
                    order.state == D3xManagerType.ORDER_STATE_OPEN &&
                    order.timestamp + globalConfig.marketOrdersTimeoutForMinute * uint32(1 minutes) <= _blockTimestamp()//确实超时了
                )
            )
        ) {
            return true;
        }
        return false;
    }

    function tradeTimeout(
        uint64[] calldata tradeNumber
    ) external
    preCheck(false/*isNewTrade*/, true/*isWriteFunction*/)
    onlyEOA {
        address who = _msgSender();

        for (uint256 i = 0; i < tradeNumber.length;) {
            D3xManagerType.Trade storage trade = _trade[tradeNumber[i]];

            require(
                trade.who == who ||
                _supportedLimitTrigger.contains(who),
                "501.trade owner"
            );

            uint8 tradeState = trade.state;
            if (tradeState == D3xManagerType.TRADE_STATE_MARKET_OPENING) {

                _openTradeMarketTimeout(trade);

            } else if (tradeState == D3xManagerType.TRADE_STATE_MARKET_CLOSING) {

                _closeTradeMarketTimeout(trade);

            } else if (tradeState == D3xManagerType.TRADE_STATE_LIMIT_OPENING) {

                _triggerTradeLimitOpeningTimeout(trade);

            } else if (
                tradeState == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING ||
                tradeState == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING ||
                tradeState == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING
            ) {

                _triggerTradeLimitTpSlLiqClosingTimeout(trade);
            } else {
                revert("502.trade wrong state");
            }

            unchecked{i++;}
        }
    }


    function _openTradeMarketTimeout(
        D3xManagerType.Trade storage trade
    )
    internal
    {
        //关闭,退款

        require(trade.state == D3xManagerType.TRADE_STATE_MARKET_OPENING, "503.trade state");

        if (trade.orderNumber != 0) {
            //如果order还没有结束,也就是超时
            _cancelPriceOrderTimeout(trade);
            require(trade.orderNumber == 0, "504.orderNumber is wrong");
        } /*else {
            //order成功触发,trade没有关闭,那就是callback+process有revert或者panic, orderState为ORDER_STATE_FINISHED_WITH_ERROR
        }*/

        _setTradeState(trade, D3xManagerType.TRADE_STATE_MARKET_OPEN_TIMEOUT);
        trade.closeTimestamp = _blockTimestamp();
        trade.closePrice = 0;

        FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(trade.currency, openTradeAnyMix(), trade.who, trade.desiredPositionInCurrency);

        _personTrade[trade.who][trade.pairCurrencyNumber].remove(trade.tradeNumber);
        _personClosedTrade[trade.who][trade.pairCurrencyNumber].push(trade.tradeNumber);
    }

    function _closeTradeMarketTimeout(
        D3xManagerType.Trade storage trade
    )
    internal
    {
        //退回到live状态

        require(trade.state == D3xManagerType.TRADE_STATE_MARKET_CLOSING, "505.trade state");

        if (trade.orderNumber != 0) {
            //如果order还没有结束,也就是超时
            _cancelPriceOrderTimeout(trade);
            require(trade.orderNumber == 0, "506.orderNumber is wrong");
        } /*else {
            //order成功触发,trade没有关闭,那就是callback+process有revert或者panic
        }*/

        _setTradeState(trade, D3xManagerType.TRADE_STATE_LIVE);
        //不管之前是什么状态,这里都清除掉closingTimestamp
        trade.closingTimestamp = 0;
    }

    function _triggerTradeLimitOpeningTimeout(
        D3xManagerType.Trade storage trade
    )
    internal
    {
        //直接退款 关单

        require(trade.state == D3xManagerType.TRADE_STATE_LIMIT_OPENING, "507.trade state");

        if (trade.orderNumber != 0) {
            //如果order还没有结束,也就是超时
            _cancelPriceOrderTimeout(trade);
            require(trade.orderNumber == 0, "508.orderNumber is wrong");
        } /*else {
            //order成功触发,trade没有关闭,那就是callback+process有revert或者panic
        }*/

        _setTradeState(trade, D3xManagerType.TRADE_STATE_LIMIT_OPEN_TIMEOUT);
        trade.closeTimestamp = _blockTimestamp();
        trade.closePrice = 0;

        FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(trade.currency, openTradeAnyMix(), trade.who, trade.desiredPositionInCurrency);

        _personTrade[trade.who][trade.pairCurrencyNumber].remove(trade.tradeNumber);
        _personClosedTrade[trade.who][trade.pairCurrencyNumber].push(trade.tradeNumber);
    }

    function _triggerTradeLimitTpSlLiqClosingTimeout(
        D3xManagerType.Trade storage trade
    )
    internal
    {
        //退回到live状态

        require(
            trade.state == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING ||
            trade.state == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING ||
            trade.state == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING,
            "509.trade wrong state"
        );

        if (trade.orderNumber != 0) {
            //如果order还没有结束,也就是超时
            _cancelPriceOrderTimeout(trade);
            require(trade.orderNumber == 0, "510.orderNumber is wrong");
        } /*else {
            //order成功触发,trade没有关闭,那就是callback+process有revert或者panic
        }*/

        _setTradeState(trade, D3xManagerType.TRADE_STATE_LIVE);
        //不管之前是什么状态,这里都清除掉closingTimestamp
        trade.closingTimestamp = 0;
    }

    //仅清楚price order,需要配合trade state的转移逻辑使用
    function _cancelPriceOrderTimeout(
        D3xManagerType.Trade storage trade
    )
    internal
    {

        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();
        D3xManagerType.Order storage order = _order[trade.orderNumber];

        require(order.state == D3xManagerType.ORDER_STATE_OPEN, "511.order state is not open");
        require(order.timestamp + globalConfig.marketOrdersTimeoutForMinute * uint32(1 minutes) <= _blockTimestamp(), "512.order is not timed out");

        trade.orderNumber = 0;
        order.state = D3xManagerType.ORDER_STATE_CANCELLED;

        _person[trade.who].pendingPriceOrderAmount--;
    }
}
