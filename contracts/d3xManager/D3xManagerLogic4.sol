// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "./D3xManagerInterface4.sol";

import "./D3xManagerType.sol";
import "../dependant/helperLibrary/FundLibrary.sol";
import "contracts/dependant/helperLibrary/ConstantLibrary.sol";
import "contracts/d3xVault/D3xVaultInterface.sol";

import "hardhat/console.sol";
//closeTradeMarketCallback _checkCloseTradeMarket _finishCloseMarketTrade
//closeTradeLimitCallback _checkCloseTradeLimit _finishCloseTradeLimit
//_closeTrade
//_calcProfitPercent _calcClosingFee _calcTraderReturn _calcTradeFee _calcNetProfit
contract D3xManagerLogic4 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
//ChainlinkClientLogic,
//TWAPPriceGetterLogic,
D3xManagerInterface4
{

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    //================================================

    //把一个仓位用market单的方式关闭
    function closeTradeMarketCallback(uint64 orderNumber) external onlySelf returns (bool) {

        (
            bool isMimicError,
        /*bytes memory mimicErrorData*/,
        //bytes memory returnData
        ) = _invokeAndCheckMimicError(
            address(this),
            abi.encodeWithSelector(
                D3xManagerInterface4.closeTradeMarketProcess.selector,
                orderNumber
            ),
            0
        );

        //revert will goes back to 'fulfill'
        if (isMimicError) {
            //ignore mimic Error reason

            D3xManagerType.Order storage order = _order[orderNumber];

            //收取govFee
            D3xManagerType.Trade storage trade = _trade[order.tradeNumber];

            //退回到live状态
            _setTradeState(trade, D3xManagerType.TRADE_STATE_LIVE);
            //不管之前是什么状态,这里都清除掉closingTimestamp
            trade.closingTimestamp = 0;

            return false;
        } else {
            //abi.decode(returnData, ());
            //no return data, need not to decode

            return true;
        }
    }

    //run another vm instance to this function!!!!!!!
    //make sure no revert will be triggered
    function closeTradeMarketProcess(uint64 orderNumber) external onlySelf {

        D3xManagerType.Order memory order = _order[orderNumber];
        _mimicErrorReturn(order.medianSpotPrice != 0, "401.median price not set");

        D3xManagerType.Trade memory trade = _trade[order.tradeNumber];
        //D3xManagerType.Pair storage pair = _pair[trade.pairNumber];

        _checkCloseTradeMarket(trade);
        _finishCloseMarketTrade(order, trade);

    }

    function _checkCloseTradeMarket(
        D3xManagerType.Trade memory trade
    )
    internal
    pure {
        _mimicErrorReturn(trade.state == D3xManagerType.TRADE_STATE_MARKET_CLOSING, "402.trade wrong state");
    }

    function _finishCloseMarketTrade(
        D3xManagerType.Order memory order,
        D3xManagerType.Trade memory trade
    )
    internal {
        _closeTrade(trade, order, order.medianSpotPrice);
    }

    //================================================

    //把一个仓位用limit触发(tp,sl,liq)单的方式关闭
    function closeTradeLimitCallback(uint64 orderNumber) external onlySelf returns (bool){


        (
            bool isMimicError,
        /*bytes memory mimicErrorData*/,
        //bytes memory returnData
        ) = _invokeAndCheckMimicError(
            address(this),
            abi.encodeWithSelector(
                D3xManagerInterface4.closeTradeLimitProcess.selector,
                orderNumber
            ),
            0
        );

        //revert will goes back to 'fulfill'
        if (isMimicError) {
            //ignore mimic Error reason

            D3xManagerType.Order storage order = _order[orderNumber];
            //退回到live状态
            D3xManagerType.Trade storage trade = _trade[order.tradeNumber];
            _setTradeState(trade, D3xManagerType.TRADE_STATE_LIVE);
            //不管之前是什么状态,这里都清除掉closingTimestamp
            trade.closingTimestamp = 0;

            return false;
        } else {
            //abi.decode(returnData, ());
            //no return data, need not to decode
            return true;
        }
    }

    //run another vm instance to this function!!!!!!!
    //make sure no revert will be triggered
    function closeTradeLimitProcess(uint64 orderNumber) external onlySelf {

        D3xManagerType.Order memory order = _order[orderNumber];
        _mimicErrorReturn(
            order.medianCandlePrice.open != 0 && order.medianCandlePrice.low != 0 && order.medianCandlePrice.high != 0,
            "412.median candle price not set while close trade"
        );

        D3xManagerType.Trade memory trade = _trade[order.tradeNumber];

        _checkCloseTradeLimit(trade);
        _finishCloseTradeLimit(order, trade);

    }

    function _checkCloseTradeLimit(
        D3xManagerType.Trade memory trade
    )
    internal
    pure {

        uint8 tradeState = trade.state;

        _mimicErrorReturn(
            tradeState == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING ||
            tradeState == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING ||
            tradeState == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING,
            "403.trade wrong state"
        );
    }

    function _finishCloseTradeLimit(
        D3xManagerType.Order memory order,
        D3xManagerType.Trade memory trade
    )
    internal {

        //D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[trade.pairNumber][trade.currency];

        //==========================================================

        bool isHit = false;
        uint64 closePrice = 0;
        uint64 liqPrice = 0;

        uint8 tradeSate = trade.state;
        //pairCurrency.longOI会在_closeTrade更新
        //==========================================================
        if (tradeSate == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING) {

            liqPrice = _calcLiquidationPrice(
                trade.openPrice,
                trade.long,
                trade.openPositionInCurrency,
                trade.leverage,
                //带入borrowingFee才能准确计算
                _calcBorrowingFee(trade)//_finishCloseTradeLimit
            );

            //清算价格可能为0!!!!!!

            //不要写到1个if里面用||连接,看起来太累
            if (order.medianCandlePrice.low <= liqPrice && liqPrice <= order.medianCandlePrice.high) {
                //夹中了  清算
                isHit = true;
                closePrice = liqPrice;
            } else if (trade.long && order.medianCandlePrice.open <= liqPrice) {
                //看涨的情况下  开盘价(最高价)比清仓价还要低, 必须清仓
                isHit = true;
                closePrice = order.medianCandlePrice.open;
            } else if (!trade.long && liqPrice <= order.medianCandlePrice.open) {
                //看空的情况下  开盘价(最低价)比清仓价还要高, 必须清仓
                isHit = true;
                closePrice = order.medianCandlePrice.open;
            } /*else {
                //清算失败
            }*/
        } else if (tradeSate == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING) {
            if (order.medianCandlePrice.low <= trade.tp && trade.tp <= order.medianCandlePrice.high) {
                //夹中了  清算
                isHit = true;
                closePrice = trade.tp;
            } else if (trade.long && trade.tp <= order.medianCandlePrice.open) {
                //看涨的情况下  开盘价(最低价)比止盈价还要高, 必须止盈
                isHit = true;
                closePrice = order.medianCandlePrice.open;
            } else if (!trade.long && order.medianCandlePrice.open <= trade.tp) {
                //看空的情况下  开盘价(最高价)比止盈价还要低, 必须止盈
                isHit = true;
                closePrice = order.medianCandlePrice.open;
            } /*else {
                //止盈失败
            }*/
        } else if (tradeSate == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING && trade.isSlSet) {
            if (order.medianCandlePrice.low <= trade.sl && trade.sl <= order.medianCandlePrice.high) {
                //夹中了  清算
                isHit = true;
                closePrice = trade.sl;
            } else if (trade.long && order.medianCandlePrice.open <= trade.sl) {
                //看涨的情况下  开盘价(最高价)比止损还要高, 必须止损
                isHit = true;
                closePrice = order.medianCandlePrice.open;
            } else if (!trade.long && trade.sl <= order.medianCandlePrice.open) {
                //看空的情况下  开盘价(最低高价)比止损价还要高, 必须止损
                isHit = true;
                closePrice = order.medianCandlePrice.open;
            } /*else {
                //止损失败
            }*/
        } else {
            //未命中,或者没有设定止损
            isHit = false;
            closePrice = 0;
        }

        _mimicErrorReturn(isHit, string(abi.encodePacked("404.candle not hit, liquidation price: ", sysPrintUint256ToHex(liqPrice))));

        //==========================================================

        /*
        function _handleOracleRewards(
            D3xOracleType.TriggeredLimitId memory _triggeredLimitId_,
            address _trader_,
            uint256 _oracleRewardDai_,
            uint256 _tokenPriceDai_
        ) private {
            uint256 oracleRewardToken = ((_oracleRewardDai_ * D3xExchangeHandlerType.PRECISION) / _tokenPriceDai_);
            D3xOracleInterface(oracle()).distributeOracleReward(_triggeredLimitId_, oracleRewardToken);

            emit TriggerFeeCharged(_trader_, _oracleRewardDai_);
        }
        */
        //先跳过 是给oracle mint D3xToken,就是给触发的服务器mint  limit开单和limit关单都需要(服务器触发都需要)
        //_handleOracleRewards(triggeredLimitId, t.trader, (v.reward1 * 2) / 10, v.tokenPriceDai);

        _closeTrade(trade, order, closePrice);

    }

    //================================================

    function _closeTrade(
        D3xManagerType.Trade memory trade,
        D3xManagerType.Order memory order,
        uint64 closePrice
    ) internal {

        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[trade.pairCurrencyNumber];
        D3xManagerType.Trade storage tradeStorage = _trade[trade.tradeNumber];

        D3xManagerType.FinishCloseTradeParam memory p;
        p.leveragedPositionInCurrency = trade.openPositionInCurrency * trade.leverage;
        uint8 tradeState = trade.state;
        {
            (uint256 profitPercentIn10, bool profitPercentIn10Win) = _calcProfitPercent(
                trade.openPrice,
                closePrice,//当前被采用的价格
                trade.long,
                trade.leverage
            );

            p.borrowingFee = _calcBorrowingFee(trade);//_closeTrade

            //console.log("D3xManagerLogic4v:_closeTrade profitPercentIn10 =%s,profitPercentIn10Win =%s,borrowingFee =%s", profitPercentIn10, profitPercentIn10Win, p.borrowingFee);
            (uint256 netProfitPercentIn10, bool netProfitPercentIn10Win) = _calcNetProfit(
                trade.openPositionInCurrency,
                profitPercentIn10,
                profitPercentIn10Win,
                p.borrowingFee
            );

            if (tradeState == D3xManagerType.TRADE_STATE_MARKET_CLOSING) {

                p.closeTradeFee = _calcTradeFee(p.leveragedPositionInCurrency, pairCurrency.tradeFeeFactorInExtraPoint);
                p.closeVaultFee = _calcCloseVaultFee(pairCurrency, p.leveragedPositionInCurrency);
                p.closeStakingFee = _calcCloseStakingFee(pairCurrency, p.leveragedPositionInCurrency);

            } else if (tradeState == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING) {

                p.closeTradeFee = trade.openPositionInCurrency * 5 / D3xManagerType.PERCENT;
                p.closeVaultFee = p.closeTradeFee / 2;
                p.closeStakingFee = p.closeTradeFee - p.closeVaultFee;

            } else if (
                tradeState == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING ||
                tradeState == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING
            ) {

                p.closeTradeFee = _calcTradeFee(p.leveragedPositionInCurrency, pairCurrency.tradeFeeFactorInExtraPoint);
                p.closeVaultFee = _calcCloseVaultFee(pairCurrency, p.leveragedPositionInCurrency);
                p.closeStakingFee = _calcCloseStakingFee(pairCurrency, p.leveragedPositionInCurrency);

            } else {
                revert("405.trade wrong state");
            }

            p.closeOracleFee = _toUint128(order.supplier.length * order.oracleFeePerSupplier);

            //================================================

            //没有了rolling fee和funding fee了 计算出用户最后应得的金额(本金+利润 或者 本金-亏损)
            p.closeReturnPositionInCurrency = _calcTraderReturn(
                trade.openPositionInCurrency,//当前还留在openTradeMix里的钱
                netProfitPercentIn10,
                netProfitPercentIn10Win,
                p.closeTradeFee + p.closeVaultFee + p.closeStakingFee + p.closeOracleFee
            );
            tradeStorage.closeReturnPositionInCurrency = p.closeReturnPositionInCurrency;
            p.leftInOpenTradeAnyMix = trade.openPositionInCurrency;
        }

        {
            D3xManagerType.PairCurrencyOIWindow storage pairCurrencyOIWindow = _pairCurrencyOIWindow[trade.pairCurrencyNumber][trade.pairCurrencyOIWindowId];
            if (trade.long) {

                if (pairCurrencyOIWindow.long < p.leveragedPositionInCurrency) {
                    pairCurrencyOIWindow.long = 0;
                } else {
                    pairCurrencyOIWindow.long -= p.leveragedPositionInCurrency;
                }

            } else {
                if (pairCurrencyOIWindow.short < p.leveragedPositionInCurrency) {
                    pairCurrencyOIWindow.short = 0;
                } else {
                    pairCurrencyOIWindow.short -= p.leveragedPositionInCurrency;
                }
            }
        }

        {
            D3xManagerType.PairCurrency storage pairCurrencyStorage = _pairCurrency[trade.pairCurrencyNumber];

            _updateAccFee(pairCurrencyStorage);//_closeTrade
            if (trade.long) {
                pairCurrencyStorage.longOI -= p.leveragedPositionInCurrency;
            } else {
                pairCurrencyStorage.shortOI -= p.leveragedPositionInCurrency;
            }
        }

        {//打款
            address currency = trade.currency;

            _mimicErrorReturn(
                p.closeTradeFee + p.closeVaultFee + p.closeStakingFee + p.closeOracleFee <= p.leftInOpenTradeAnyMix,
                "413.close fees are large then open position, config problem"
            );
            //一定够付, 因为这3个费用都是按照百分比计算的,只要参数设定不过分
            address openTradeAnyMixAddress = openTradeAnyMix();
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                tradeFeeAnyReceive(),
                p.closeTradeFee
            );
            /*FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                vault(),
                p.closeVaultFee
            );*/
            //这里需要把各种asset的vault拆开
            //这里需要check allowance
            bytes32 vaultName = _currency[currency].vaultName;
            _mimicErrorReturn(vaultName != ConstantLibrary.ZERO_BYTES, "406.currency's vault name is not set");
            address vaultAddress = ns().getSingle(vaultName);
            _mimicErrorReturn(vaultAddress != address(0), "407.currency's vault address is not set");
            {
                //check the asset and allowance
                address assetAddress = D3xVaultInterface(vaultAddress).asset();
                _mimicErrorReturn(assetAddress == currency, "414.vault's asset and currency mismatch");

                uint256 allowance = IERC20(currency).allowance(address(this), vaultAddress);
                if (allowance < p.closeVaultFee + p.closeReturnPositionInCurrency/*最恶劣情况*/) {
                    IERC20(currency).approve(vaultAddress, type(uint256).max);
                }
            }
            //vault不是trusted,所以需要先转到manager名下
            FundLibrary._fundFromSafetyBoxToSelf(currency, openTradeAnyMixAddress, p.closeVaultFee);
            //再从manager转到vault
            D3xVaultInterface(vaultAddress).receiveProfit(p.closeVaultFee, trade.who);


            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                stakingAnyReceive(),
                p.closeStakingFee
            );
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                oracleAnyReceive(),
                p.closeOracleFee
            );

            p.leftInOpenTradeAnyMix -= p.closeTradeFee + p.closeVaultFee + p.closeStakingFee + p.closeOracleFee;


            if (p.leftInOpenTradeAnyMix < p.closeReturnPositionInCurrency) {
                //用户赚钱了 不够 补差额

                //剩下的全部返还 D3XShareInterface(share()).sendAssets(p.closeReturnPositionInCurrency - daiLeftInMix, trade.who);
                FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                    currency,
                    openTradeAnyMix(),
                    trade.who,
                    p.leftInOpenTradeAnyMix
                );

                //补差额 从vault里转差额
                /*FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                    currency,
                    vault(),
                    trade.who,
                    p.closeReturnPositionInCurrency - p.leftInOpenTradeAnyMix
                );*/
                //如果差额不够 就报错
                {
                    //先check一下balance
                    uint256 vaultBalance = IERC20(currency).balanceOf(vaultAddress);
                    _mimicErrorReturn(
                        p.closeReturnPositionInCurrency - p.leftInOpenTradeAnyMix <= vaultBalance,
                        "408.vault's currency is insufficient"
                    );
                }

                //先从vault take到manager名下
                D3xVaultInterface(vaultAddress).takeAsset(
                    p.closeReturnPositionInCurrency - p.leftInOpenTradeAnyMix,
                    trade.who
                );
                //再打给trade.who
                FundLibrary._fundFromSelfToSBOrSafetyBox(
                    currency,
                    trade.who,
                    p.closeReturnPositionInCurrency - p.leftInOpenTradeAnyMix
                );


            } else {
                //trade.closeReturnPositionInCurrency <= p.leftInOpenTradeAnyMix
                //足够,差额给vault

                //返还给用户
                if (0 < p.closeReturnPositionInCurrency) {
                    FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                        currency,
                        openTradeAnyMix(),
                        trade.who,
                        p.closeReturnPositionInCurrency
                    );
                }

                //剩余的钱打给vault
                if (p.closeReturnPositionInCurrency < p.leftInOpenTradeAnyMix) {
                    /*FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                        currency,
                        openTradeAnyMix(),
                        vault(),
                        p.leftInOpenTradeAnyMix - p.closeReturnPositionInCurrency
                    );*/
                    //vault不是trusted,所以需要先转到manager名下
                    FundLibrary._fundFromSafetyBoxToSelf(
                        currency,
                        openTradeAnyMixAddress,
                        p.leftInOpenTradeAnyMix - p.closeReturnPositionInCurrency
                    );
                    //再从manager转到vault
                    D3xVaultInterface(vaultAddress).receiveAsset(
                        p.leftInOpenTradeAnyMix - p.closeReturnPositionInCurrency,
                        trade.who
                    );

                }
            }
        }

        //被市价单手动关仓的
        if (tradeState == D3xManagerType.TRADE_STATE_MARKET_CLOSING) {
            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_MARKET_CLOSED);
        } else if (tradeState == D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSING) {
            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_LIMIT_LIQ_CLOSED);
        } else if (tradeState == D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSING) {
            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_LIMIT_TP_CLOSED);
        } else if (tradeState == D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSING) {
            _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_LIMIT_SL_CLOSED);
        } else {
            revert("409.trade wrong state");
        }
        tradeStorage.borrowingFee += p.borrowingFee;
        tradeStorage.closeTradeFee = p.closeTradeFee;
        tradeStorage.closeVaultFee = p.closeVaultFee;
        tradeStorage.closeStakingFee = p.closeStakingFee;
        tradeStorage.closeOracleFee = p.closeOracleFee;

        tradeStorage.closeTimestamp = _blockTimestamp();
        tradeStorage.closePrice = closePrice;

        _personTrade[trade.who][trade.pairCurrencyNumber].remove(trade.tradeNumber);
        _personClosedTrade[trade.who][trade.pairCurrencyNumber].push(trade.tradeNumber);
        //console.log("D3xManagerLogic4:_closeTrade:trade.closePrice = %s", closePrice);
    }

    //================================================

    //真实(去杠杆)利润百分比,仅通过价格计算出朴素的数据
    function _calcProfitPercent(
        uint64 openPrice,//_openPrice_ 开仓时的价格
        uint64 currentPrice,//_tp_, _sl_  需要计算时的价格
        bool long,//方向
        uint8 leverage//杠杆倍率
    )
    private
    pure
    returns (
    //为0时, isProfit为true
        uint256 profitPercentIn10,
        bool isProfit
    ) {

        if (openPrice == 0 || openPrice == currentPrice) {
            return (0, true);
        }

        uint64 priceDelta = 0;
        if (long && openPrice < currentPrice) {
            priceDelta = currentPrice - openPrice;
            isProfit = true;
        } else if (!long && currentPrice < openPrice) {
            priceDelta = openPrice - currentPrice;
            isProfit = true;
        } else if (long && currentPrice < openPrice) {
            priceDelta = openPrice - currentPrice;
            isProfit = false;
        } else if (!long && openPrice < currentPrice) {
            priceDelta = currentPrice - openPrice;
            isProfit = false;
        } else {
            revert("410.profit percent calc error");
        }

        profitPercentIn10 = uint256(priceDelta)//分子1
            * D3xManagerType.PERCENT //转化为Percent
            * D3xManagerType.PRECISION//乘以精度
            * leverage//分子2
            / openPrice;//分母

        /*p =
            (
                (
                    _buy_
                        ?
                        //long的时候   算sl的时候   _currentPrice_(sl)-_openPrice_ 是一个负数
                        int256(_currentPrice_) - int256(_openPrice_)
                        :
                        int256(_openPrice_) - int256(_currentPrice_)
                ) * 100 //percent
                * int256(D3XExchangeHandlerType.PRECISION) //P 带精度
                * int256(_leverage_)
            )
            / int256(_openPrice_);*/

        //当算sl的时候  因为是负数, 所以永远返回sl的百分比
        //p = p > maxPnlP ? maxPnlP : p;

        //900% PnL
        if (isProfit && uint256(D3xManagerType.MAX_GAIN_P) * D3xManagerType.PRECISION < profitPercentIn10) {
            profitPercentIn10 = uint256(D3xManagerType.MAX_GAIN_P) * D3xManagerType.PRECISION;
        }
    }

    function _calcCloseVaultFee(
        D3xManagerType.PairCurrency memory pairCurrency,
        uint128 leveragedPosition
    ) internal pure returns (uint128) {
        return _toUint128(
            uint256(leveragedPosition) * pairCurrency.closeVaultFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }


    function _calcCloseStakingFee(
        D3xManagerType.PairCurrency memory pairCurrency,
        uint128 leveragedPosition
    ) internal pure returns (uint128) {
        return _toUint128(
            uint256(leveragedPosition) * pairCurrency.closeStakingFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }

    //返回应该退还的本金
    function _calcTraderReturn(
        uint128 positionInCurrency,
        uint256 netProfitPercentIn10,
        bool netProfitWin,
        uint128 reduction
    ) internal pure returns (uint128){

        /*int value = int(_collateral_)
            + int(_collateral_) * _percentProfit_ / int(D3xPairType.PRECISION) / 100
            - int(_rolloverFee_) - _fundingFee_;

        //    uint constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)
        if (value <= int(_collateral_) * int(100 - D3XPairType.LIQ_THRESHOLD_P) / 100) {
            return 0;
        }

        value -= int(_closingFee_);

        return value > 0 ? uint(value) : 0;*/

        //先假设所有本金都需要退还
        uint128 plus = positionInCurrency;
        uint128 minus = 0;
        if (netProfitWin) {
            //如果用户赚钱了 再多退
            plus += _toUint128(
                uint256(positionInCurrency)
                * netProfitPercentIn10
                / D3xManagerType.PRECISION //还原精度
                / D3xManagerType.PERCENT //还原百分号
            );
        } else {
            //如果用户亏钱的 就少退
            minus += _toUint128(
                uint256(positionInCurrency)
                * netProfitPercentIn10
                / D3xManagerType.PRECISION //还原精度
                / D3xManagerType.PERCENT //还原百分号
            );
        }

        //可能穿仓,用户的本金都不够扣
        uint128 back = minus < plus ? plus - minus : 0;
        if (
            back
            <=
            positionInCurrency * (D3xManagerType.PERCENT - D3xManagerType.LIQ_THRESHOLD_P) / D3xManagerType.PERCENT
        ) {
            //超过了清算线, 不足10%的原本金被强行收走
            return 0;
        }

        if (reduction < back) {
            return back - reduction;
        } else {
            //closingFee和tradeFee都不够付了
            return 0;
        }
    }

    //带入borrowing fee之后,修正利润率
    function _calcNetProfit(
        uint128 positionInCurrency,
    //D3xManagerType.Trade storage trade,
        uint256 profitPercentIn10,
        bool profitWin,
        uint128 borrowingFee
    ) internal pure returns (
        uint256 netProfitPercentIn10,
        bool netProfitWin
    ){

        //_updateBorrowingFee(pairCurrency);

        //计算borrowing fee的计算, 其中计算了 净利率
//        uint256 temp = trade.long ? pairCurrency.accFeeLong : pairCurrency.accFeeShort;
//        temp = temp - trade.accFeePaidForPair;
//        borrowingFee = (trade.openPositionInCurrency * trade.leverage * temp) / 1e10 / 100; // 1e18 (DAI)

        uint256 borrowingFeePercentIn10 =
            uint256(borrowingFee) //分子
            * D3xManagerType.PERCENT //转换成百分号
            * D3xManagerType.PRECISION//乘以精度
            /// trade.openPositionInCurrency;//分母
            / positionInCurrency;//分母

        if (profitWin) {
            if (borrowingFeePercentIn10 <= profitPercentIn10) {
                //borrowingFee的亏损比盈利要少,扣除后仍然盈利
                netProfitPercentIn10 = profitPercentIn10 - borrowingFeePercentIn10;
                netProfitWin = true;
            } else {
                //变成亏损
                netProfitPercentIn10 = borrowingFeePercentIn10 - profitPercentIn10;
                netProfitWin = false;
            }
        } else {
            //已经是亏损了,继续亏损
            netProfitPercentIn10 = profitPercentIn10 + borrowingFeePercentIn10;
            netProfitWin = false;
        }
    }

}
