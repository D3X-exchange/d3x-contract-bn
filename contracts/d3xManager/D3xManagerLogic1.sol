// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "../chainlinkClient/ChainlinkClientLogic.sol";
import "../twapPriceGetter/TWAPPriceGetterLogic.sol";
import "./D3xManagerInterface1.sol";

import "./D3xManagerType.sol";
import "contracts/interface/chainlink/IChainlinkFeed.sol";
import "./D3xManagerInterface3.sol";
import "./D3xManagerInterface4.sol";
import "../dependant/helperLibrary/ConstantLibrary.sol";
import "contracts/interface/x1/IExOraclePriceData.sol";

import "hardhat/console.sol";

//Oracle Callback
contract D3xManagerLogic1 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
ChainlinkClientLogic,
TWAPPriceGetterLogic,//for d3x price
D3xManagerInterface1
{

//    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
//    using EnumerableSet for EnumerableSet.UintSet;
//    using Chainlink for Chainlink.Request;

    //读取chainlink的价格
    function requestPriceOrder(
        uint64 tradeNumber,
        uint8 orderType,
        uint32 fromPriceTimestamp,
        uint32 fromTimestamp,
        uint32 toTimestamp
    )
    external
    onlySelf
    returns (uint256 /*orderNumber*/){

        D3xManagerType.GlobalConfig memory globalConfig = _getGlobalConfig();

        //storage 旗下的state仅读取一次!!
        D3xManagerType.Trade storage trade = _getTrade(tradeNumber);

        require(trade.orderNumber == 0, "001.another order is hanged up");
        address who = trade.who;

        //最多5个price order
        {
            uint8 pendingPriceOrderAmount = _person[who].pendingPriceOrderAmount;
            require(
                pendingPriceOrderAmount <= globalConfig.maxConcurrentPriceOrder,
                "002.request too much pricing order"
            );
            _person[who].pendingPriceOrderAmount = pendingPriceOrderAmount + 1;
        }
        uint64 orderNumber;
        {
            uint64 currentOrderNumber = _currentOrderNumber;
            currentOrderNumber++;
            _currentOrderNumber = currentOrderNumber;
            orderNumber = currentOrderNumber;
        }

        trade.orderNumber = orderNumber;
        //tradeMemory.orderNumber = orderNumber; 不会用到

        /*bytes32 job =
            orderType == D3xManagerType.ORDER_TYPE_MARKET_OPEN ||
            orderType == D3xManagerType.ORDER_TYPE_MARKET_CLOSE ?
                D3xManagerType.CHAINLINK_JOB_MARKET :
                D3xManagerType.CHAINLINK_JOB_LIMIT;*/

        //open a new order

        D3xManagerType.Pair memory pair = _pair[trade.pairNumber];

        {
            uint8 nodePriceThreshold = globalConfig.nodePriceThreshold;
            uint128 oracleFeePerSupplier = _calcOracleFee(
                trade.desiredPositionInCurrency,
                trade.leverage,
                _pairCurrency[trade.pairCurrencyNumber].oracleFeeFactorInExtraPoint
            ) / nodePriceThreshold;

            _order[orderNumber] = D3xManagerType.Order({
                orderNumber: orderNumber,
                who: who,
                timestamp: _blockTimestamp(),
                job: ConstantLibrary.ZERO_BYTES,
                from: pair.from,
                to: pair.to,
                orderType: orderType,
                tradeNumber: tradeNumber,
                state: D3xManagerType.ORDER_STATE_OPEN,
                fromPriceTimestamp: fromPriceTimestamp,
                fromTimestamp: fromTimestamp,
                toTimestamp: toTimestamp,
                threshold: nodePriceThreshold,
                reserved72: 0,
                oracleFeePerSupplier: oracleFeePerSupplier,
                reserved128: 0,
                chainlinkRequestId: new bytes32[](0),
                supplier: new address[](0),
                spotPrice: new uint64[](0),
                candlePrice: new D3xManagerType.CandlePrice[](0),
                medianSpotPrice: 0,
                medianCandlePrice: D3xManagerType.CandlePrice(0, 0, 0),
                orderFinishError: bytes("")
            });
        }
        //send price oracle requests to all nodes
        //lycrus to-do however hard code only one here

        /*Chainlink.Request memory linkRequest = buildChainlinkRequest(
            job,
            //call back to interface 1
            address(this),
            this.fulfillRequestPriceOrder.selector
        );

        {
            D3xManagerType.Pair storage pair = _pair[trade.pairNumber];

            //都到了buffer里,用于调用chainlink
            linkRequest.add("from", string(abi.encodePacked(pair.from)));
            linkRequest.add("to", string(abi.encodePacked(pair.to)));

            if (orderType == D3xManagerType.ORDER_TYPE_LIMIT_OPEN || orderType == D3xManagerType.ORDER_TYPE_LIMIT_CLOSE) {
                linkRequest.addUint("fromBlock", fromBlock);
            }
        }*/
        bytes32[] storage chainlinkRequestId = _getOrder(orderNumber).chainlinkRequestId;

        uint256 supportedSupplierLength = _supportedSupplier.length();
        require(0 < _supportedSupplier.length(), "003.empty order nodes");
        for (uint256 i = 0; i < supportedSupplierLength;) {
            //for normal
            /*address nodeAddress = _node.at(i);

            bytes32 chainlinkRequestId = sendChainlinkRequestTo(
                nodeAddress,
                linkRequest,
                0//linkFeePerNode
            );*/

            //for test, do not ask node job
            bytes32 requestId = bytes32(keccak256(abi.encode(
                orderNumber,
                i,
                orderType,
                pair.from,
                pair.to,
                fromPriceTimestamp,
                fromTimestamp,
                toTimestamp
            )));

            chainlinkRequestId.push(requestId);

            _chainlinkRequestIdToOrderId[requestId] = orderNumber;

            emit OrderRequest(orderNumber, requestId);

            unchecked{i++;}
        }

        return orderNumber;
    }

    //chainlink的回调
    function fulfillRequestPriceOrder(
        bytes32 chainlinkRequestId,
        uint256 priceData
    )
    external
        //chainlink的跟踪状态,校验了请求的supplier/oracle提供商对不对,以及是否已经被填充过
        /*for test
        recordChainlinkFulfillment(chainlinkRequestId)*/ {
        address supplierAddress = _msgSender();
        require(_supportedSupplier.contains(supplierAddress), "004.only supported suppliers");


        uint64 orderNumber = _chainlinkRequestIdToOrderId[chainlinkRequestId];
        require(orderNumber != 0, "005.fulfill wrong order number");
        //useless and save gas
        delete _chainlinkRequestIdToOrderId[chainlinkRequestId];

        D3xManagerType.Order storage order = _getOrder(orderNumber);

        //sload once
        address[] memory orderFormerSuppliers = order.supplier;
        uint256 orderFormerSuppliersLength = orderFormerSuppliers.length;

        for (uint256 i = 0; i < orderFormerSuppliersLength;) {
            //just sload once
            require(orderFormerSuppliers[i] != supplierAddress, "006.supplier address supplies twice");
            unchecked{i++;}
        }

        if (order.state == D3xManagerType.ORDER_STATE_FINISHED || order.state == D3xManagerType.ORDER_STATE_CANCELLED) {
            return;
        }

        D3xManagerType.Trade storage trade = _getTrade(order.tradeNumber);
        //D3xManagerType.PairCurrency storage pairCurrency = _getPairCurrency(trade.pairCurrencyNumber);
        //memory read all data
        D3xManagerType.Pair memory pair = _pair[trade.pairNumber];

        //maybe 0
        uint64 feedPrice = _fetchFeedPrice(pair);
        uint8 orderType = order.orderType;
        address currency = trade.currency;

        if (orderType == D3xManagerType.ORDER_TYPE_MARKET_OPEN || orderType == D3xManagerType.ORDER_TYPE_MARKET_CLOSE) {
            //market

            //我们应该自行encode decode,最低位的价格
            //如果market不存在了,就关闭,给出0

            //{oracleTimestamp64|X|X|priceData64}
            //uint256 spotPrice = uint256(uint64(priceData));
            //uint256 oracleTimestamp = uint256(uint64(priceData >> 192));
            uint64 spotPrice = uint64(priceData);

            uint32 oracleTimestamp = uint32(priceData >> 192);
            require(order.fromPriceTimestamp <= oracleTimestamp, "013.spot oracle timestamp");


            emit OrderFulfill(orderNumber, orderType, supplierAddress, oracleTimestamp, spotPrice, 0, 0);

            if (_isPriceWithinDeviation(spotPrice, feedPrice, pair.maxDeviationFactorInExtraPoint)) {

                order.spotPrice.push(spotPrice);

                order.supplier.push(supplierAddress);
                _supplier[supplierAddress][currency].cumulativeSupplyCount ++;

                if (order.spotPrice.length == order.threshold) {

                    //排序后取中位的
                    uint64 medianSpotPrice = _median(order.spotPrice);
                    order.medianSpotPrice = medianSpotPrice;

                    trade.orderNumber = 0;
                    //tradeMemory.orderNumber = 0;
                    order.state = D3xManagerType.ORDER_STATE_FINISHED;
                    //orderMemory.state = D3xManagerType.ORDER_STATE_FINISHED;
                    _person[order.who].pendingPriceOrderAmount--;

                    //callback
                    //跳转对应的业务处理逻辑
                    if (orderType == D3xManagerType.ORDER_TYPE_MARKET_OPEN) {
                        //D3xManagerInterface3(address(this)).openTradeMarketCallback(orderNumber);
                        try D3xManagerInterface3(address(this)).openTradeMarketCallback(orderNumber) returns (bool success){

                            if (success) {
                                _distributeOracleFee(currency, orderFormerSuppliers, supplierAddress, order.oracleFeePerSupplier);
                            }

                        } catch Error(string memory reason) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(reason);
                        } catch Panic(uint256 errorCode) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(abi.encodePacked("panic: ", Strings.toString(errorCode)));
                        } /*catch (bytes memory lowLevelData) {
                            //only catch Error,  no panic, no low-level all reverts
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态

                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = lowLevelData;
                        }*/

                    } else {

                        //D3xManagerInterface4(address(this)).closeTradeMarketCallback(orderNumber);
                        try D3xManagerInterface4(address(this)).closeTradeMarketCallback(orderNumber) returns (bool success){

                            if (success) {
                                _distributeOracleFee(currency, orderFormerSuppliers, supplierAddress, order.oracleFeePerSupplier);
                            }

                        }catch Error(string memory reason) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(reason);
                        } catch Panic(uint256 errorCode) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(abi.encodePacked("panic: ", Strings.toString(errorCode)));
                        } /*catch (bytes memory lowLevelData) {
                            //only catch Error,  no panic, no low-level all reverts
                            //先不做处理 等待超时关单
                            //这里应该改成关单失败自动回到live状态

                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = lowLevelData;
                        }*/
                    }

                }

            }
            //else ignore this spot price

        } else if (orderType == D3xManagerType.ORDER_TYPE_LIMIT_OPEN || orderType == D3xManagerType.ORDER_TYPE_LIMIT_CLOSE) {

            D3xManagerType.CandlePrice memory candle;
            //oracle的格式也不一样
            //{oracleTimestamp64|low64|high64|open64}
            //candle.open = uint256(uint64(priceData));
            //candle.high = uint256(uint64(priceData >> 64));
            //candle.low = uint256(uint64(priceData >> 128));
            //uint256 oracleTimestamp = uint256(uint64(priceData >> 192));
            candle.open = uint64(priceData);
            candle.high = uint64(priceData >> 64);
            candle.low = uint64(priceData >> 128);

            uint32 oracleTimestamp = uint32(priceData >> 192);
            require(order.fromPriceTimestamp <= oracleTimestamp, "014.candle oracle timestamp");

            emit OrderFulfill(orderNumber, orderType, supplierAddress, oracleTimestamp, candle.open, candle.high, candle.low);

            require(
                (candle.high == 0 && candle.low == 0) ||
                (candle.open <= candle.high && candle.low <= candle.open && candle.low > 0),
                "007.invalid candle"
            );


            if (_isPriceWithinDeviation(candle.high, feedPrice, pair.maxDeviationFactorInExtraPoint) ||
                _isPriceWithinDeviation(candle.low, feedPrice, pair.maxDeviationFactorInExtraPoint)) {

                order.candlePrice.push(candle);

                order.supplier.push(supplierAddress);
                _supplier[supplierAddress][currency].cumulativeSupplyCount ++;

                if (order.candlePrice.length == order.threshold) {

                    //open high low每个都是独立取中位的
                    //还是重复读取
                    D3xManagerType.CandlePrice memory medianCandlePrice = _medianCandlePrice(order.candlePrice);
                    order.medianCandlePrice = medianCandlePrice;

                    trade.orderNumber = 0;
                    order.state = D3xManagerType.ORDER_STATE_FINISHED;
                    _person[order.who].pendingPriceOrderAmount--;

                    //callback
                    //跳转对应的业务处理逻辑
                    if (orderType == D3xManagerType.ORDER_TYPE_LIMIT_OPEN) {

                        //D3xManagerInterface3(address(this)).openTradeLimitCallback(orderNumber);
                        try D3xManagerInterface3(address(this)).openTradeLimitCallback(orderNumber)returns (bool success){

                            if (success) {
                                _distributeOracleFee(currency, orderFormerSuppliers, supplierAddress, order.oracleFeePerSupplier);
                            }

                        }catch Error(string memory reason) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(reason);
                        } catch Panic(uint256 errorCode) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(abi.encodePacked("panic: ", Strings.toString(errorCode)));
                        }/*catch (bytes memory lowLevelData) {
                            //only catch Error,  no panic, no low-level all reverts
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = lowLevelData;
                        }*/

                    } else {

                        //D3xManagerInterface4(address(this)).closeTradeLimitCallback(orderNumber);
                        try D3xManagerInterface4(address(this)).closeTradeLimitCallback(orderNumber) returns (bool success){

                            if (success) {
                                _distributeOracleFee(currency, orderFormerSuppliers, supplierAddress, order.oracleFeePerSupplier);
                            }

                        }catch Error(string memory reason) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(reason);
                        } catch Panic(uint256 errorCode) {
                            //说明callback+process有revert或者panic
                            //这里需要用户手动触发超时关闭

                            //这里应该改成关单失败自动回到live状态
                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = bytes(abi.encodePacked("panic: ", Strings.toString(errorCode)));
                        }/*catch (bytes memory lowLevelData) {
                            //only catch Error,  no panic, no low-level all reverts
                            //先不做处理 等待超时关单
                            //这里应该改成关单失败自动回到live状态

                            order.state = D3xManagerType.ORDER_STATE_FINISHED_WITH_ERROR;
                            order.orderFinishError = lowLevelData;
                        }*/
                    }

                }
            }

        } else {
            revert("008.fulfill unknown order type");
        }
    }

    //============================

    /*function _calcOracleFee(D3xManagerType.Trade memory trade) internal view returns (uint128){
        //因为还没有开单,所以名义仓位是还没有扣除各种govFee tradeFee之类的初始的费用

        D3xManagerType.PairCurrency storage pairCurrency = _pairCurrency[trade.pairNumber][trade.currency];

        return trade.desiredPositionInCurrency * trade.leverage * pairCurrency.oracleFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT;
    }*/

    function _calcOracleFee(
        uint128 desiredPositionInCurrency,
        uint8 leverage,
        uint24 oracleFeeFactorInExtraPoint
    ) internal pure returns (uint128){
        //因为还没有开单,所以名义仓位是还没有扣除各种govFee tradeFee之类的初始的费用
        return _toUint128(
            uint256(desiredPositionInCurrency) * leverage * oracleFeeFactorInExtraPoint / D3xManagerType.EXTEND_POINT
        );
    }

    /*function _distributeOracleFee(D3xManagerType.Trade memory trade, D3xManagerType.Order memory order) internal {

        for (uint256 i = 0; i < order.supplier.length; i ++) {
            D3xManagerType.Supplier storage supplier = _supplier[trade.currency][order.supplier[i]];

            supplier.cumulativeOracleFee += order.oracleFeePerSupplier;
            supplier.oracleFee += order.oracleFeePerSupplier;
        }
    }*/

    function _distributeOracleFee(
        address currency,
        address[] memory orderFormerSuppliers,
        address orderLatestSupplier,
        uint128 orderOracleFeePerSupplier
    ) internal {

        for (uint256 i = 0; i < orderFormerSuppliers.length;) {
            D3xManagerType.Supplier storage formerSupplier = _supplier[orderFormerSuppliers[i]][currency];

            formerSupplier.cumulativeOracleFee += orderOracleFeePerSupplier;
            formerSupplier.oracleFee += orderOracleFeePerSupplier;

            unchecked{i ++;}
        }

        D3xManagerType.Supplier storage supplier = _supplier[orderLatestSupplier][currency];

        supplier.cumulativeOracleFee += orderOracleFeePerSupplier;
        supplier.oracleFee += orderOracleFeePerSupplier;
    }

    //============================

    function fetchFeedPrice(uint16 pairNumber) external view returns (uint64){
        D3xManagerType.Pair memory pair = _pair[pairNumber];

        return _fetchFeedPrice(pair);
    }

    //fulfill 读取最近的feed价格
    function _fetchFeedPrice(D3xManagerType.Pair memory pair) private view returns (uint64) {


        if (pair.feed1 == address(0)) {
            return 0;
        }

        uint256 feedPrice = 0;
        int256 feedPriceInt256;
        if (pair.accessType == D3xManagerType.ORACLE_ACCESS_TYPE_CHAINLINK) {
            (, feedPriceInt256,,,) = IChainlinkFeed(pair.feed1).latestRoundData();

            uint256 feedPriceUint256 = _int256ToUint256(feedPriceInt256);

            if (pair.feedCalculation == D3xManagerType.FEED_CALCULATION_NORMAL) {

                //feedPrice = feedPriceUint256 * D3xManagerType.PRECISION / 1e8;

                feedPrice = feedPriceUint256 * (10 ** pair.feedPriceMultiplyDecimal) / (10 ** pair.feedPriceDivideDecimal);

            } else if (pair.feedCalculation == D3xManagerType.FEED_CALCULATION_INVERSE) {

                //feedPrice = D3xManagerType.PRECISION * 1e8 / feedPriceUint256;
                revert("011.unknown feed calculation");

            } else if (pair.feedCalculation == D3xManagerType.FEED_CALCULATION_COMPOSITION) {
                //COMBINE 需要拿第2个喂价东西来除以第一个  看起来没有直接的价格对
                /*(, int256 feedPrice2Int256, , ,) = IChainlinkFeed(pair.feed2).latestRoundData();
                uint256 feedPrice2Uint256 = _int256ToUint256(feedPrice2Int256);

                feedPrice = (feedPriceUint256 * D3xManagerType.PRECISION) / feedPrice2Uint256;*/
                revert("011.unknown feed calculation");

            } else {
                revert("009.unknown feed calculation");
            }


        } else if (pair.accessType == D3xManagerType.ORACLE_ACCESS_TYPE_X1) {
            (, feedPriceInt256,,,) = IExOraclePriceData(address(0x64481ebfFe69d688d754e09918e82C89D8Da2507))
            .latestRoundData(
                string(abi.encodePacked(pair.from)),
                address(0x6CF2a39d1c85aDFB50DA183060DC0d46529F3f9C)
            );

            uint256 feedPriceUint256 = _int256ToUint256(feedPriceInt256);

            if (pair.feedCalculation == D3xManagerType.FEED_CALCULATION_NORMAL) {

                //feedPrice = feedPriceUint256 * D3xManagerType.PRECISION / 1e6;
                feedPrice = feedPriceUint256 * (10 ** pair.feedPriceMultiplyDecimal) / (10 ** pair.feedPriceDivideDecimal);

            } else if (pair.feedCalculation == D3xManagerType.FEED_CALCULATION_INVERSE) {

                //feedPrice = D3xManagerType.PRECISION * 1e6 / feedPriceUint256;
                revert("011.unknown feed calculation");

            } else if (pair.feedCalculation == D3xManagerType.FEED_CALCULATION_COMPOSITION) {
                revert("010.unsupported oracle");
            } else {
                revert("011.unknown feed calculation");
            }
        } else {
            revert("012.unknown oracle type");
        }


        return _toUint64(feedPrice);
    }

    //判断spotPrice和feedPrice的偏差
    function _isPriceWithinDeviation(uint64 spotPrice, uint64 feedPrice, uint24 maxDeviationFactorInExtraPoint) private pure returns (bool) {

        //deltaPrice / feedPrice <= deviationRatio
        //deltaPrice <= feedPrice * deviationRatio/1e6
        return
            spotPrice == 0 ||//报价关闭
            feedPrice == 0 ||//chainlink数据没有
            (
                feedPrice <= spotPrice
                    ? spotPrice - feedPrice
                    : feedPrice - spotPrice
            )
            <=
            _toUint64(

                uint256(feedPrice)
                * maxDeviationFactorInExtraPoint
                / D3xManagerType.EXTEND_POINT
            );
    }

    //===================

    //排序后取中位的
    function _median(uint64[] memory _array_) internal pure returns (uint64) {
        _sort(_array_, 0, _array_.length);

        return
            _array_.length % 2 == 0
                ? (_array_[_array_.length / 2 - 1] + _array_[_array_.length / 2]) / 2
                : _array_[_array_.length / 2];
    }

    function _sort(uint64[] memory _array_, uint256 _begin_, uint256 _end_) internal pure {
        if (_begin_ >= _end_) {
            return;
        }

        uint256 j = _begin_;
        uint256 pivot = _array_[j];

        for (uint256 i = _begin_ + 1; i < _end_;) {
            if (_array_[i] < pivot) {
                _swap(_array_, i, ++j);
            }
            unchecked{++i;}
        }

        _swap(_array_, _begin_, j);
        _sort(_array_, _begin_, j);
        _sort(_array_, j + 1, _end_);
    }

    // Median function
    function _swap(uint64[] memory _array_, uint256 _i_, uint256 _j_) private pure {
        (_array_[_i_], _array_[_j_]) = (_array_[_j_], _array_[_i_]);
    }

    function _medianCandlePrice(D3xManagerType.CandlePrice[] memory _array_) private pure returns (
    //uint _open_, uint _high_, uint _low_
        D3xManagerType.CandlePrice memory
    ) {

        uint256 length = _array_.length;

        uint64[] memory opens = new uint64[](length);
        uint64[] memory highs = new uint64[](length);
        uint64[] memory lows = new uint64[](length);

        for (uint256 i; i < length;) {
            opens[i] = _array_[i].open;
            highs[i] = _array_[i].high;
            lows[i] = _array_[i].low;

            unchecked {
                ++i;
            }
        }

        _sort(opens, 0, length);
        _sort(highs, 0, length);
        _sort(lows, 0, length);

        bool isLengthEven = length % 2 == 0;
        uint256 halfLength = length / 2;

        uint64 _open_ = isLengthEven ? (opens[halfLength - 1] + opens[halfLength]) / 2 : opens[halfLength];
        uint64 _high_ = isLengthEven ? (highs[halfLength - 1] + highs[halfLength]) / 2 : highs[halfLength];
        uint64 _low_ = isLengthEven ? (lows[halfLength - 1] + lows[halfLength]) / 2 : lows[halfLength];

        D3xManagerType.CandlePrice memory ret = D3xManagerType.CandlePrice(
            _open_,
            _high_,
            _low_
        );

        return ret;
    }
}
