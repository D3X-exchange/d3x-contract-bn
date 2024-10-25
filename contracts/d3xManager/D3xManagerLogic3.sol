// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "./D3xManagerInterface3.sol";

import "./D3xManagerType.sol";
import "contracts/d3xManager/D3xManagerInterface1.sol";
import "../dependant/helperLibrary/FundLibrary.sol";

import "hardhat/console.sol";

//openTradeMarketCallback
//openTradeLimitCallback
contract D3xManagerLogic3 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
//ChainlinkClientLogic,
//TWAPPriceGetterLogic,
D3xManagerInterface3
{

//    using SafeERC20 for IERC20;
//    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function openTradeMarketCallback(uint64 orderNumber) external onlySelf returns (bool){

        (
            bool isMimicError,
            bytes memory mimicErrorData,
        //bytes memory returnData
        ) = _invokeAndCheckMimicError(
            address(this),
            abi.encodeWithSelector(
                D3xManagerInterface3.openTradeMarketProcess.selector,
                orderNumber
            ),
            0
        );

        //有异常就直接revert到fulfill
        //revert will goes back to 'fulfill'

        if (isMimicError) {
            //ignore mimic Error reason

            uint64 tradeNumber = _order[orderNumber].tradeNumber;
            //收取govFee
            D3xManagerType.Trade memory trade = _trade[tradeNumber];

            uint128 openGovFee = _calcOpenGovFee(
                trade.desiredPositionInCurrency * trade.leverage,
                _pairCurrency[trade.pairCurrencyNumber].openGovFeeFactorInExtraPoint
            );
            {
                FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                    trade.currency,
                    openTradeAnyMix(),
                    openGovFeeAnyReceive(),
                    openGovFee
                );
            }

            //退款
            _cancelOpeningTrade(
                tradeNumber,
                openGovFee,
                D3xManagerType.TRADE_STATE_MARKET_OPEN_CANCELLED,
                mimicErrorData
            );

            return false;
        } else {
            //abi.decode(returnData, ());
            //no return data, need not to decode

            //开单成功
            return true;
        }

    }

    //run another vm instance to this function!!!!!!!
    //make sure no revert will be triggered
    function openTradeMarketProcess(uint64 orderNumber) external onlySelf {
        D3xManagerType.Order memory order = _order[orderNumber];
        //console.log("openTradeMarketProcess:order.medianSpotPrice= ", order.medianSpotPrice);
        _mimicErrorReturn(order.medianSpotPrice != 0, "121.median price not set");

        uint64 tradeNumber = order.tradeNumber;
        D3xManagerType.Trade memory trade = _trade[tradeNumber];
        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[trade.pairCurrencyNumber];

        (/*uint256 priceImpactP*/, uint64 priceAfterImpact) = _checkOpenTradeMarket(
            trade,
            order.medianSpotPrice,
            _pair[trade.pairNumber].spreadFactorInExtraPoint
        );
        //console.log("openTradeMarketProcess priceAfterImpact = ", priceAfterImpact);

        _finishOpenTrade(tradeNumber, trade, order, pairCurrency, priceAfterImpact);
    }

    //trade在price喂价后重新检查状态,包括了新价格的检查,顺道返回新价格
    function _checkOpenTradeMarket(
        D3xManagerType.Trade memory trade,
        uint64 openPrice,
        uint24 spreadFactorInExtraPoint
    )
    internal
    view
    returns (
        uint24 priceImpactRateInExtraPoint,
        uint64 priceAfterImpact
    ){

        _mimicErrorReturn(trade.state == D3xManagerType.TRADE_STATE_MARKET_OPENING, "122.trade wrong state");

        //_openTradePrep
        //无

        return _checkOpenTrade(trade, openPrice, spreadFactorInExtraPoint);
    }

    //================================================================================================================

    function openTradeLimitCallback(uint64 orderNumber) external onlySelf returns (bool){

        (
            bool isMimicError,
            bytes memory mimicErrorData,
        //bytes memory returnData
        ) = _invokeAndCheckMimicError(
            address(this),
            abi.encodeWithSelector(
                D3xManagerInterface3.openTradeLimitProcess.selector,
                orderNumber
            ),
            0
        );

        //有异常就直接revert到fulfill
        //revert will goes back to 'fulfill'

        if (isMimicError) {
            //ignore mimic Error reason

            uint64 tradeNumber = _order[orderNumber].tradeNumber;
            //收取govFee
            D3xManagerType.Trade memory trade = _trade[tradeNumber];

            uint128 openGovFee = _calcOpenGovFee(
                trade.desiredPositionInCurrency * trade.leverage,
                _pairCurrency[trade.pairCurrencyNumber].openGovFeeFactorInExtraPoint
            );

            {
                FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                    trade.currency,
                    openTradeAnyMix(),
                    openGovFeeAnyReceive(),
                    openGovFee
                );
            }

            //退款
            _cancelOpeningTrade(
                tradeNumber,
                openGovFee,
                D3xManagerType.TRADE_STATE_LIMIT_OPEN_CANCELLED,
                mimicErrorData
            );


            return false;
        } else {
            //abi.decode(returnData, ());
            //no return data, need not to decode

            //开单成功
            return true;
        }
    }

    function openTradeLimitProcess(uint64 orderNumber) external onlySelf {

        D3xManagerType.Order memory order = _order[orderNumber];
        _mimicErrorReturn(
            order.medianCandlePrice.open != 0 &&
            order.medianCandlePrice.low != 0 &&
            order.medianCandlePrice.high != 0,
            "123.median candle price not set while open trade"
        );

        uint64 tradeNumber = order.tradeNumber;
        D3xManagerType.Trade memory trade = _trade[tradeNumber];
        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[trade.pairCurrencyNumber];

        (/*uint256 priceImpactP*/, uint64 priceAfterImpact) = _checkOpenTradeLimit(
            order,
            trade,
            _pair[trade.pairNumber].spreadFactorInExtraPoint
        );

        _finishOpenTrade(tradeNumber, trade, order, pairCurrency, priceAfterImpact);
    }

    function _checkOpenTradeLimit(
        D3xManagerType.Order memory order,
        D3xManagerType.Trade memory trade,
        uint24 spreadFactorInExtraPoint
    )
    internal
    view
    returns (
        uint24 priceImpactRateInExtraPoint,
        uint64 priceAfterImpact
    ){
        _mimicErrorReturn(trade.state == D3xManagerType.TRADE_STATE_LIMIT_OPENING, "124.trade wrong state");

        uint64 openPrice = type(uint64).max;

        if (order.medianCandlePrice.low <= trade.desiredOpenPrice &&
            trade.desiredOpenPrice <= order.medianCandlePrice.high) {
            //夹中了
            openPrice = trade.desiredOpenPrice;
        } else if (trade.tradeType == D3xManagerType.TRADER_TYPE_LIMIT) {
            //限价单,没夹中,看是不是跳盘

            if (trade.long && order.medianCandlePrice.open <= trade.desiredOpenPrice) {
                //做多时,期望价一定比开单时候的市价要低,只要价格向下穿过期望价就可以触发
                //开盘价(<最高价) <= 期望价
                openPrice = order.medianCandlePrice.open;
            } else if (!trade.long && trade.desiredOpenPrice <= order.medianCandlePrice.open) {
                //做空时,期望价一定比开单时候的市价要高,只要价格向上穿过期望价就可以触发
                openPrice = order.medianCandlePrice.open;
            }
            //没命中
        } else if (trade.tradeType == D3xManagerType.TRADER_TYPE_STOP_LIMIT) {
            //追高单,没夹中,看是不是跳盘

            if (trade.long && trade.desiredOpenPrice <= order.medianCandlePrice.open) {
                //做多时,期望价一定比开单时候的市价要高,只要价格向上穿过期望价就可以触发
                //开盘价(<最高价) <= 期望价
                openPrice = order.medianCandlePrice.open;
            } else if (!trade.long && order.medianCandlePrice.open <= trade.desiredOpenPrice) {
                //做空时,期望价一定比开单时候的市价要低,只要价格向下穿过期望价就可以触发
                openPrice = order.medianCandlePrice.open;
            }
            //没命中
        } /*else {
            //市价不存在价格穿越情形
        }*/

        _mimicErrorReturn(openPrice != type(uint64).max,
            string(abi.encodePacked(
                "411.candle not hit, desiredOpenPrice price: ",
                sysPrintUint256ToHex(trade.desiredOpenPrice)
            ))
        );

        return _checkOpenTrade(trade, openPrice, spreadFactorInExtraPoint);

    }

    //================================================================================================================

    //被 _checkOpenTradeMarket  _checkOpenTradeLimit 调用
    function _checkOpenTrade(
        D3xManagerType.Trade memory trade,
        uint64 openPrice,
        uint24 spreadFactorInExtraPoint
    )
    internal
    view
    returns (
        uint24 priceImpactRateInExtraPoint,
        uint64 priceAfterImpact
    ){

        //计算了静态价差
        uint64 priceWithFixedSpread = _calcFixedSpreadPrice(openPrice, spreadFactorInExtraPoint, trade.long);

        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[trade.pairCurrencyNumber];

        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();

        //计算了动态价差的最大限度
        (priceImpactRateInExtraPoint, priceAfterImpact) = _calcDynamicSpreadPriceImpact(
            globalConfig,
            priceWithFixedSpread,//_openPrice
            pairCurrency,
            trade.long,
            trade.desiredPositionInCurrency * trade.leverage
        );

        //带滑点的价格delta
        /*uint256 maxSlippagedGap = trade.slippagePercentIn10 > 0 ?
            //wantedPrice是用户开市价单请求时的openPrice,再回调之后就变成了order.wantedPrice也就是_trade_.openPrice
            trade.desiredOpenPrice * trade.slippagePercentIn10 / D3xManagerType.PRECISION / D3xManagerType.PERCENT :
            //1%默认滑点
            trade.desiredOpenPrice / D3xManagerType.PERCENT; // 1% by default*/

        uint64 maxSlippagedGap = _toUint64(
            uint256(trade.desiredOpenPrice) * trade.slippageFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
        //console.log("_checkOpenTrade.maxSlippagedGap %s, %s, %s", maxSlippagedGap, trade.desiredOpenPrice, priceAfterImpact);
        if (trade.long) {
            //实际开仓价 < 最大滑点限度下的报价
            _mimicErrorReturn(priceAfterImpact <= trade.desiredOpenPrice + maxSlippagedGap, "125.long slippage out");
        } else {
            _mimicErrorReturn(priceAfterImpact >= trade.desiredOpenPrice - maxSlippagedGap, "126.short slippage out");
        }

        //desiredTp 为自动计算
        if (0 < trade.desiredTp) {
            if (trade.long) {
                //对于long的情况, 最终算上价差的价格如果比止盈的价格还要高  那是反逻辑的
                _mimicErrorReturn(priceAfterImpact < trade.desiredTp, "127.long price goes over tp");
            } else {
                _mimicErrorReturn(trade.desiredTp < priceAfterImpact, "128.short price goes over tp");
            }
        }
        //desiredIsSlSet设定了sl
        if (trade.desiredIsSlSet) {
            if (trade.long) {
                //对于long的情况, 最终算上价差的价格如果比止盈的价格还要高  那是反逻辑的
                _mimicErrorReturn(trade.desiredSl < priceAfterImpact, "129.long price goes over sl");
            } else {
                _mimicErrorReturn(priceAfterImpact < trade.desiredSl, "130.short price goes over sl");
            }
        }
        //超过了OI
        {
            _mimicErrorReturn(
                (trade.long ?
                    pairCurrency.longOI :
                    pairCurrency.shortOI
                ) +
                trade.desiredPositionInCurrency * trade.leverage
                <= pairCurrency.maxOI,
                "131.open OI too much"
            );
            //            DexConfigInterface(configAddress).withinMaxGroupOi(_pairIndex_, _buy_, levPositionSizeDai);
        }

        _mimicErrorReturn(
            uint256(priceImpactRateInExtraPoint) * trade.leverage <=
            uint256(globalConfig.maxNegativePnlOnOpenWith10) * D3xManagerType.PRECISION,
            "132.maxNegativePnlOnOpenP"
        );
    }

    //市价单的开单价=执行时的价格 +/- 静态价差
    //计算静态价差
    function _calcFixedSpreadPrice(uint64 _price_, uint24 _spreadFactorInExtraPoint_, bool _long_) private pure returns (uint64) {
        uint64 priceDiff = _toUint64(
            uint256(_price_ * _spreadFactorInExtraPoint_) / D3xManagerType.EXTEND_POINT
        );

        return _long_ ? _price_ + priceDiff : _price_ - priceDiff;
    }

    //_registerTrade
    // Shared code between market & limit callbacks
    //被exchange handler(自身)调用  正式分配利润上单
    //被market和limit开单调用
    function _finishOpenTrade(
        uint64 tradeNumber,
        D3xManagerType.Trade memory trade,
        D3xManagerType.Order memory order,
        D3xManagerType.PairCurrency memory pairCurrency,
        uint64 openPriceWithSpread
    ) internal {

        D3xManagerType.Trade storage tradeStorage = _trade[tradeNumber];
        D3xManagerType.PairCurrency storage pairCurrencyStorage = _pairCurrency[trade.pairCurrencyNumber];

        D3xManagerType.FinishOpenTradeParam memory p;

        //实际开仓价格为算上利差的价格
        tradeStorage.openPrice = openPriceWithSpread;

        //稍后会因为扣除本金而重新计算
        p.leveragedPositionInCurrency = trade.desiredPositionInCurrency * trade.leverage;
        address currency = trade.currency;

        address openTradeAnyMixAddress = openTradeAnyMix();
        // 2. Calculate gov fee (- referral fee if applicable)
        //0.03% 打到govFee
        {
            p.openGovFee = _calcOpenGovFee(
                p.leveragedPositionInCurrency,
                pairCurrency.openGovFeeFactorInExtraPoint
            );
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                openGovFeeAnyReceive(),
                p.openGovFee
            );
        }

        //0.03% 打到质押合约
        {
            p.openStakingFee = _calcStakingFee(
                p.leveragedPositionInCurrency,
                pairCurrency.openStakingFeeFactorInExtraPoint
            );
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                stakingAnyReceive(),
                p.openStakingFee
            );
        }

        // 3. Calculate Market/Limit fee
        //btc 0.0200000000 为什么是0.02
        //开单的时候 0.004% -> Market/Limit 关单的时候 0.004% -> Market/Limit  开单总共0.08 关单总共0.08
        //0.02% 打给tradeFee
        {
            p.openTradeFee = _calcTradeFee(
                p.leveragedPositionInCurrency,
                pairCurrency.tradeFeeFactorInExtraPoint
            );
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                tradeFeeAnyReceive(),
                p.openTradeFee
            );
        }

        {
            p.openOracleFee = _toUint128(order.supplier.length * order.oracleFeePerSupplier);
            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                oracleAnyReceive(),
                p.openOracleFee
            );
        }

        // 3.2 Distribute Oracle fee and send DAI amount to vault if applicable
        if (trade.state == D3xManagerType.TRADE_STATE_LIMIT_OPENING) {

            p.openLimitTriggerFee = _calcOpenLimitTriggerFee(pairCurrency, p.leveragedPositionInCurrency);

            //trigger奖励 仅记账
            require(trade.openLimitTrigger != address(0), "133.trade.openLimitTrigger is empty");
            D3xManagerType.Trigger storage triggerDetail = _trigger[trade.openLimitTrigger][currency];
            triggerDetail.openLimitTriggerFee += p.openLimitTriggerFee;
            triggerDetail.cumulativeOpenLimitTriggerFee += p.openLimitTriggerFee;
            triggerDetail.cumulativeOpenLimitTriggerCount ++;

            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                openTradeAnyMixAddress,
                triggerAnyReceive(),
                p.openLimitTriggerFee
            );
        }

        //剩余的开仓本金留在openTradeAnyMix里!!!!!!

        // 3.1 Deduct gov fee, SSS fee (previously dev fee), Market/Limit fee
        p.openPositionInCurrency = trade.desiredPositionInCurrency
            - p.openGovFee
            - p.openTradeFee
            - p.openStakingFee
            - p.openOracleFee
            - p.openLimitTriggerFee;
        tradeStorage.openPositionInCurrency = p.openPositionInCurrency;
        p.leveragedPositionInCurrency = p.openPositionInCurrency * trade.leverage;

        //修正tp和sl, 为关单做准备,
        //_trade_.tp = _correctTp(_trade_.openPrice, _trade_.leverage, _trade_.tp, _trade_.buy);
        {
            //check if tp is not set or are over 900% for the median price
            uint64 desiredTp = trade.desiredTp;
            uint64 extremeTp = _calcTpSlPrice(openPriceWithSpread, trade.long, trade.leverage, D3xManagerType.MAX_GAIN_P, true);
            if (desiredTp == 0) {
                //如果tp使用缺省值,一样就设定为极限tp
                desiredTp = extremeTp;
            }
            if (trade.long) {
                //trade.tp = Math.min(desiredTp, extremeTp);
                tradeStorage.tp = desiredTp < extremeTp ? desiredTp : extremeTp;
            } else {
                //trade.tp = Math.max(desiredTp, extremeTp);
                tradeStorage.tp = desiredTp < extremeTp ? extremeTp : desiredTp;
            }
        }

        //_trade_.sl = _correctSl(_trade_.openPrice, _trade_.leverage, _trade_.sl, _trade_.buy);
        {
            bool desiredIsSlSet = trade.desiredIsSlSet;
            tradeStorage.isSlSet = desiredIsSlSet;
            //不设定Sl  也就是价格为0 由服务器按照-90%来清算
            if (!desiredIsSlSet) {
                //保持为0
                tradeStorage.sl = 0;
            } else {
                uint64 desiredSl = trade.desiredSl;
                uint64 extremeSl = _calcTpSlPrice(openPriceWithSpread, trade.long, trade.leverage, D3xManagerType.MAX_SL_P, false);
                if (trade.long) {
                    //trade.sl = Math.max(trade.desiredSl, extremeSl);
                    tradeStorage.sl = desiredSl < extremeSl ? extremeSl : desiredSl;
                } else {
                    //trade.sl = Math.min(trade.desiredSl, extremeSl);
                    tradeStorage.sl = desiredSl < extremeSl ? desiredSl : extremeSl;
                }
            }

        }

        //先更新历史费用,之后更改pairOI
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        //不要再使用pairCurrency
        _updateAccFee(pairCurrencyStorage);//_finishOpenTrade
        //开但时记录
        tradeStorage.accFeePaid = trade.long ? pairCurrencyStorage.accFeeLongStore : pairCurrencyStorage.accFeeShortStore;
        tradeStorage.accFeePaidTimestamp = _blockTimestamp();

        // 7. Store final trade in storage contract
        //呼叫exchangeData修改Trade的状态
        //D3xExchangeDataInterface(exchangeData()).storeTrade(_trade_, D3xExchangeDataType.TradeInfo(0, v.tokenPriceDai, v.levPosDai, 0, 0, false));
        if (trade.long) {
            pairCurrencyStorage.longOI += p.leveragedPositionInCurrency;
        } else {
            pairCurrencyStorage.shortOI += p.leveragedPositionInCurrency;
        }

        {
            uint32 windowId = _getWindowId(_blockTimestamp(), _getGlobalConfig());
            D3xManagerType.PairCurrencyOIWindow storage pairCurrencyOIWindow = _pairCurrencyOIWindow[trade.pairCurrencyNumber][windowId];
            if (trade.long) {
                pairCurrencyOIWindow.long += p.leveragedPositionInCurrency;
            } else {
                pairCurrencyOIWindow.short += p.leveragedPositionInCurrency;
            }
            tradeStorage.pairCurrencyOIWindowId = windowId;
        }


        tradeStorage.openGovFee += p.openGovFee;
        tradeStorage.openStakingFee += p.openStakingFee;
        tradeStorage.openTradeFee += p.openTradeFee;
        tradeStorage.openLimitTriggerFee += p.openLimitTriggerFee;
        tradeStorage.openOracleFee += p.openOracleFee;

        uint32 current = _blockTimestamp();
        tradeStorage.createTimestamp = current;
        tradeStorage.tpTimestamp = current;
        tradeStorage.slTimestamp = current;

        _setTradeState(tradeStorage, D3xManagerType.TRADE_STATE_LIVE);

        return;
    }

    function _calcOpenGovFee(
    //D3xManagerType.Pair storage pair,
    //D3xManagerType.PairCurrency storage pairCurrency,
        uint128 leveragedPositionSize,
        uint24 openGovFeeFactorInExtraPoint
    ) internal pure returns (uint128) {
        //openFeeP  btc 0_300000000    Opening a trade: 0.08% 其中 0.03% -> Governance Fund
        return _toUint128(
            uint256(leveragedPositionSize) * /*pairCurrency.*/openGovFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }

    function _calcStakingFee(
    //D3xManagerType.PairCurrency memory pairCurrency,
        uint128 leveragedPositionSize,
        uint24 openStakingFeeFactorInExtraPoint
    ) internal pure returns (uint128) {
        return _toUint128(
            uint256(leveragedPositionSize) * /*pairCurrency.*/openStakingFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }

    function _calcOpenLimitTriggerFee(
        D3xManagerType.PairCurrency memory pairCurrency,
        uint128 leveragedPositionSize
    ) internal pure returns (uint128){
        return _toUint128(
            uint256(leveragedPositionSize)  * pairCurrency.openLimitTriggerFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }

    function _cancelOpeningTrade(uint64 tradeNumber, uint128 openGovFee, uint8 cancelledState, bytes memory cancelReason) internal {
        D3xManagerType.Trade storage trade = _trade[tradeNumber];

        _setTradeState(trade, cancelledState);
        trade.closeTimestamp = _blockTimestamp();
        trade.closePrice = 0;
        trade.cancelReason = cancelReason;
        trade.openGovFee = openGovFee;

        address who = trade.who;

        FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
            trade.currency,
            openTradeAnyMix(),
            who,
            //会收取govFee
            trade.desiredPositionInCurrency - openGovFee
        );

        _personTrade[who][trade.pairCurrencyNumber].remove(tradeNumber);
        _personClosedTrade[who][trade.pairCurrencyNumber].push(tradeNumber);

    }
}
