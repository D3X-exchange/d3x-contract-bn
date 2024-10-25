// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library D3xManagerType {

    //1 extend point = 0.000001
    //价格用2**64
    uint40 internal constant PRECISION = 1e10; // 10 decimals
    uint8 internal constant PERCENT = 100;
    uint24 internal constant EXTEND_POINT = 1_000_000;
    //因为每个仓位都是独立的, 所以将订单和仓位合二为一为交易
    //order+position=trade

//    uint256 internal constant TRADE_TYPE_MARKET = 1;
//    uint256 internal constant TRADE_TYPE_LIMIT = 2;
//    uint256 internal constant TRADE_TYPE_STOP_MARKET = 3;


    uint8 internal constant ORDER_STATE_OPEN = 1;
    uint8 internal constant ORDER_STATE_FINISHED = 2;
    uint8 internal constant ORDER_STATE_CANCELLED = 3;
    uint8 internal constant ORDER_STATE_FINISHED_WITH_ERROR = 4;

    //请求价格的原因
    //for callback
    uint8 internal constant ORDER_TYPE_MARKET_OPEN = 1;//原本是个市价单,需要喂价,喂价之后开仓
    uint8 internal constant ORDER_TYPE_MARKET_CLOSE = 2;
    //不区分limit和stop limit
    uint8 internal constant ORDER_TYPE_LIMIT_OPEN = 3;
    uint8 internal constant ORDER_TYPE_LIMIT_CLOSE = 4;


    uint8 internal constant TRADER_TYPE_MARKET = 1;
    uint8 internal constant TRADER_TYPE_LIMIT = 2;
    uint8 internal constant TRADER_TYPE_STOP_LIMIT = 3;

    //openTradeMarket                                   null -> market opening 市价开单
    //openTradeLimit                                    market opening(order)市价开单成功 -> live
    //openTradeMarketTimeout                            market opening市价打喂价超时 -> market open timeout
    //auto                                              market opening市价打喂价失败 -> market open cancelled

    //openTradeLimit                                    null -> limit pending 限价开单挂单成功, 等待服务器喂价
    //cancelTradeLimit                                  limit pending -> limit cancelled

    //triggerLimitOrder(TRADE_STATE_LIMIT_OPENING)      limit pending -> limit opening(order)限价触发(蜡烛)+市价打开?
    //price order                                       limit opening(order)限价触发开单成功 -> live
    //triggerTradeLimitOpeningTimeout                   limit opening(order)限价触发超时 -> limit opening timeout
    //auto                                              limit opening(order)限价触发失败 -> limit opening cancelled

    //closeTradeMarket                                  live -> market closing(order)市价关闭
    //price order                                       market closing(order)市价关闭 -> closed
    //closeTradeMarketTimeout                           market closing(order)市价关闭 -> timeout//怎么解决?

    //triggerLimitOrder(TRADE_STATE_TP_MARKET_CLOSING)  live -> tp market closing(order)限价触发(蜡烛)+市价关闭
    //price order                                       tp market closing(order)限价触发(蜡烛)+市价关闭 -> closed
    //triggerTradeLimitTpClosingTimeout                 tp market closing(order)限价触发(蜡烛)+市价关闭 -> timeout//找一个解决方案,这不能回滚状态回live

    //triggerLimitOrder(TRADE_STATE_SL_MARKET_CLOSING)  live -> sl market closing(order)限价触发(蜡烛)+市价关闭
    //price order                                       sl market closing(order)限价触发(蜡烛)+市价关闭 -> closed
    //triggerTradeLimitSlClosingTimeout                 sl market closing(order)限价触发(蜡烛)+市价关闭 -> timeout//找一个解决方案,这不能回滚状态回live

    //triggerLimitOrder(TRADE_STATE_LIQ_MARKET_CLOSING) live -> liq market closing(order)限价触发(蜡烛)+市价关闭
    //price order                                       liq market closing(order)限价触发(蜡烛)+市价关闭 -> closed
    //triggerTradeLimitLiqClosingTimeout                liq market closing(order)限价触发(蜡烛)+市价关闭 -> timeout//找一个解决方案,这不能回滚状态回live

    //开单有市价单和限价单
    //关单有手动市价单和 设定的tp,sl以及默认的liq这3种"限价单"(用价格触发的'市价单',但是oracle需要喂蜡烛图用来验证是否能触发tp,sl,liq)
    //所有的市价单都要有价格回调

    uint8 internal constant TRADE_STATE_EMPTY = 0;//错误的仓位
    uint8 internal constant TRADE_STATE_LIVE = 1;//正常的仓位

    uint8 internal constant TRADE_STATE_MARKET_OPENING = 2;//正在请求price order

    uint8 internal constant TRADE_STATE_LIMIT_PENDING = 3;//limit单子进入了深度,等待服务器触发
    uint8 internal constant TRADE_STATE_LIMIT_OPENING = 4;//limit单子触发开单 也是trigger

    //live的单子 需要服务器监听tp sl 和 liq

    uint8 internal constant TRADE_STATE_MARKET_CLOSING = 5;//正在请求price order
    uint8 internal constant TRADE_STATE_LIMIT_TP_CLOSING = 6;//单子触发limit tp 也是trigger
    uint8 internal constant TRADE_STATE_LIMIT_SL_CLOSING = 7;//单子触发limit sl 也是trigger
    uint8 internal constant TRADE_STATE_LIMIT_LIQ_CLOSING = 8;//单子触发limit liq 也是trigger

    uint8 internal constant TRADE_STATE_MARKET_CLOSED = 9;//结束的单子

    //cancel
    uint8 internal constant  TRADE_STATE_LIMIT_CANCELLED = 10;//limit单子进入了深度,但是取消了
    //time out
    uint8 internal constant TRADE_STATE_MARKET_OPEN_TIMEOUT = 11;//市价开单超时 或者callback有revert
    uint8 internal constant TRADE_STATE_LIMIT_OPEN_TIMEOUT = 12;//限价开单超时  或者callback有revert

    uint8 internal constant TRADE_STATE_MARKET_OPEN_CANCELLED = 13; //order失败,市价开单失败
    uint8 internal constant TRADE_STATE_LIMIT_OPEN_CANCELLED = 14; //order失败,限价开单失败

    uint8 internal constant TRADE_STATE_LIMIT_TP_CLOSED = 15;//tp关单结束
    uint8 internal constant TRADE_STATE_LIMIT_SL_CLOSED = 16;//sl关单结束
    uint8 internal constant TRADE_STATE_LIMIT_LIQ_CLOSED = 17;//tp关单结束

    //=======================================================

//    uint256 internal constant  TRADE_PIVOT_LIMIT_PENDING = 1;
//    uint256 internal constant  TRADE_PIVOT_LIMIT_CANCELLED = 2;
//    uint256 internal constant  TRADE_PIVOT_TRADE_LIVE = 3;//同时用来显示系统最新的开单
//    uint256 internal constant  TRADE_PIVOT_UPDATE_TP_SL = 4;
//    uint256 internal constant  TRADE_PIVOT_CLOSE = 5;
//    uint256 internal constant  TRADE_PIVOT_OPENING_CANCELLED = 6;

    //=======================================================

    uint8  internal constant ORACLE_ACCESS_TYPE_CHAINLINK = 1;
    uint8  internal constant ORACLE_ACCESS_TYPE_X1 = 2;
    //=======================================================

    //bytes32 internal constant CHAINLINK_JOB_MARKET = hex"6461383264313534663663613464623161643631343765653531616233343231";
    //bytes32 internal constant CHAINLINK_JOB_LIMIT = hex"3637666266393336323639613465313139353264346465383563303030396334";


    uint16 internal constant MAX_SL_P = 75; // -75% PNL
    uint16 internal constant MAX_GAIN_P = 900; // 900% PnL (10x)
    //uint256 internal constant MAX_EXECUTE_TIMEOUT = 5; // 5 blocks
    uint16 internal constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)

    uint8 internal constant FEED_CALCULATION_NORMAL = 1;
    uint8 internal constant FEED_CALCULATION_INVERSE = 2;
    uint8 internal constant FEED_CALCULATION_COMPOSITION = 3;

    bytes32 internal constant  MIMIC_ERROR = bytes32("=========MIMIC++ERROR=========");

    struct GlobalConfig {

        //----------------------------------------------
        //Pack:8+8+8+8+24+8+16+32+32+8+8+96
        bool enableNewTrade;
        bool enableWriteFunction;

        //uint256 maxTradePerPair;//3
        //uint256 maxConcurrentPriceOrder;//5
        uint8 maxTradePerPairCurrency;//3
        uint8 maxConcurrentPriceOrder;//5

        //uint256 maxNegativePnlOnOpenIn10; //40_0000000000
        uint24 maxNegativePnlOnOpenWith10; //40 -> 40_0000000000

        //uint256 nodePriceThreshold;
        uint8 nodePriceThreshold;

        //uint256 marketOrdersTimeout;
        uint16 marketOrdersTimeoutForMinute;

        //uint256 oiStartTimestamp; //1701081018
        uint32 oiStartTimestamp; //1701081018
        //uint256 oiWindowsDuration; // 7200
        uint32 oiWindowsDuration; // 7200
        //uint256 oiWindowsCount; //2
        uint8 oiWindowsCount; //2

        bool isFaucetSupported;

        uint96 reserved104;
        //----------------------------------------------

    }

    struct Currency {
        bytes32 vaultName;
        uint8 decimal;
    }

    //4*256
    struct Pair {

        /*
        //    struct Pair {
        //        string from;
        //        string to;
        //        Feed feed;
        //        uint spreadP;               // PRECISION
        //        uint groupIndex;
        //        uint feeIndex;
        //    }
        //    struct Feed {
        //        address feed1;
        //        address feed2;
        //        FeedCalculation feedCalculation;
        //        uint maxDeviationP;
        //    } // PRECISION (%)
        // from,to: BTC,USD,
        // feed.feed1 0x6ce185860a4963106506C203335A2910413708e9,  https://docs.chain.link/data-feeds/price-feeds/addresses?network=arbitrum&page=1&search=btc https://arbiscan.io/address/0x6ce185860a4963106506C203335A2910413708e9
        // feed.feed2 0x0000000000000000000000000000000000000000,
        // feed.feedCalculation 0, DEFAULT
        // feed.maxDeviationP 20_0000000000, 20%
        // spreadP 400000000,
        // groupIndex 0,
        // feeIndex 0
        //另一个pair feed的例子  pairIndex 29  EUR/JPY
        //feed1 0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84 EUR / USD
        //feed2 0x3dD6e51CB9caE717d5a8778CF79A04029f9cFDF8 JPY / USD
        //feedCalculation 2  COMBINE
        //maxDeviationP 10_0000000000 10 10%
        */

        //uint256 spreadPercentIn10;               // PRECISION 静态价差 btc,eth 400000000 0.04, 其他为0   0.04%

        //----------------------------------------------
        bytes32 from;
        bytes32 to;
        //----------------------------------------------
        //Pack:16+24+24+8+8+16+160
        uint16 pairNumber;
        //uint256 maxDeviationPercentIn10;              //10_0000000000 10 10%
        uint24 maxDeviationFactorInExtraPoint;         //100000 -> 0.10_0000 -> 10%
        //uint64 spreadPercentIn10;                     // PRECISION 静态价差 btc,eth 400000000 0.04, 其他为0   0.04%
        uint24 spreadFactorInExtraPoint;               //400 -> 0.00_0400 -> 0.04%   fixed spread
        uint8 feedPriceMultiplyDecimal; //当 feedCalculation 工作时,用以调节从online oracle 读取价格的小数点精度
        uint8 feedPriceDivideDecimal; //当 feedCalculation 工作时,用以调节从online oracle 读取价格的小数点精度
        uint16 reserved32;
        address feed1; //online oracle address,  0x0 for disable
        //----------------------------------------------

        //Pack:160+8+8+80
        address feed2; //online oracle address,  0x0 for disable, work with feedCalculation

        //bytes32 accessType;
        uint8 accessType;  //how to read online oracle

         //how to calc online oracle data
        //    uint8 internal constant FEED_CALCULATION_NORMAL = 1;
        //    uint8 internal constant FEED_CALCULATION_INVERSE = 2;
        //    uint8 internal constant FEED_CALCULATION_COMPOSITION = 3;
        uint8 feedCalculation;
        uint8 pricePrintDecimal;
        uint72 reserved72;
    }

    struct PairCurrency {

        //----------------------------------------------
        //Pack:16+16+160+8+8+24+24
        uint16 pairCurrencyNumber;
        uint16 pairNumber;
        address currency;

        //uint256 minLeverage;
        //uint256 maxLeverage;
        uint8 minLeverage;
        uint8 maxLeverage;

        //他的openFeeP 其实是 Governance Fund
        //uint256 openGovFeePercentIn10;                // PRECISION (% of leveraged pos) 300000000 0.03 0.03%  他的openFeeP
        uint24 openGovFeeFactorInExtraPoint;           //300  0.00_0300 0.03%  他的openFeeP
        //打给d3x单币质押合约
        //uint256 openStakingFeePercentIn10;         // PRECISION (% of leveraged pos) 300000000 0.03 0.03%
        uint24 openStakingFeeFactorInExtraPoint;    //300 0.00_0300 0.03%
        //----------------------------------------------

        //----------------------------------------------
        //Pack:24+24+24+24+24+24+32+80
        //打给limit 开单的trigger  我们和gtrade不一样 直接收取总的百分比 而不是从tradeFee(market/limit fee)里抽取
        //uint256 openLimitTriggerFeePercentIn10;       // 50000000 0.005 0.005%
        uint24 openLimitTriggerFeeFactorInExtraPoint;  // 500 0.00_0500 0.005%

        //nftLimitOrderFeeP
        //uint256 closeVaultFeePercentIn10;             // PRECISION (% of leveraged pos) 300000000 0.03 0.03%
        uint24 closeVaultFeeFactorInExtraPoint;        //300 0.00_0300 0.03%
        //uint256 closeStakingFeePercentIn10;        // PRECISION (% of leveraged pos) 600000000 0.03
        uint24 closeStakingFeeFactorInExtraPoint;   //300 0.00_0300 0.03%

        //开单关单都有
        //uint256 tradeFeePercentIn10;                  // PRECISION (% of leveraged pos) 200000000 0.02 0.02%
        uint24 tradeFeeFactorInExtraPoint;             //200 0.00_0200 0.02%
        //perSupplier
        //uint256 oracleFeePercentIn10;                 // PRECISION (% of leveraged pos) 50000000  0.005 0.005%
        uint24 oracleFeeFactorInExtraPoint;            //50 0.00_0050 0.005%

        //uint256 referralFeePercentIn10;               // PRECISION (% of leveraged pos) 100000000 0.01 0.01%
        uint24 referralFeeFactorInExtraPoint;          //100 0.00_0100 0.01%
        //uint256 minLevPosDai;          // 1e18 (collateral x leverage, useful for min fee)  7500.000000000000000000    ==> minLeveragedPosition

        //!!!!!!!!!!!!!!!!!!!
        //uint256 accFeeLastUpdated;// 170631913  170625224
        uint32 accFeeLastUpdated;// 170631913  170625224

        uint80 reserved80;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        //uint256 minLeveragedPositionInCurrency;
        uint128 minLeveragedPositionInCurrency;
        //uint256 maxLeveragedPositionInCurrency;
        uint128 maxLeveragedPositionInCurrency;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        //==============for borrowing fee
        //uint256 borrowingFeeRate; ///和gtrade不一样,这里不再是百分比后的数据
        //uint128 borrowingFeeRatePerDay; ///和gtrade不一样,这里不再是百分比后的数据

        uint24 borrowingFeePerDayFactorInExtraPoint;  //30 0.00_0030 0.003%
        uint104 reserved104;
        //uint256 accFeeLongStore; // 1e10 (%) 172179176196  179732656   界面上的open interest L
        uint128 accFeeLongStore; // 1e10 (%) 172179176196  179732656   界面上的open interest L
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        //uint256 accFeeShortStore; // 1e10 (%) 15390925079  4382826204  界面上的open interest L
        uint128 accFeeShortStore; // 1e10 (%) 15390925079  4382826204  界面上的open interest L

        //uint256 longOI;
        uint128 longOI;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        //uint256 longOI;
        uint128 shortOI;
        //uint256 maxOI;
        uint128 maxOI;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        //==============动态价差
        //uint256 onePercentDepthAbove; // DAI 需要定期喂进来 用于计算动态价差
        uint128 onePercentDepthAbove; // DAI 需要定期喂进来 用于计算动态价差
        //uint256 onePercentDepthBelow; // DAI 需要定期喂进来 用于计算动态价差
        uint128 onePercentDepthBelow; // DAI 需要定期喂进来 用于计算动态价差
        //----------------------------------------------

    }

    /*struct ActivePairCurrencyDetail {
        //----------------------------------------------
        //Pack:16+240
        //uint256 pairNumber;
        uint16 pairCurrencyNumber;
        uint240 reserved240;
        //----------------------------------------------

    }*/

    //代表一个仓位,他是每个仓位隔离的
    //开仓单可以是市价单或者限价单
    //限价单都可以用"价格触发"的市价单来模拟,因为这里只有banker,没有对手
    //所以stop limit单子和普通的limit没有什么两样,除去stop的一开始的可见性(交易所也可以读取,但是不在交易队列里)
    //平仓单只能是市价单, 没有限价单,但是可以设定tp和sl,  tp和sl到了之后  触发order, 这里只能触发market order
    //用tp和sl的价格来触发市价单, 这个和limit的行为很像, 标准是到了tp的价格,挂一个限价单或者市价单
    //但是这里谁都知道触发价格,并且限价单就是触发的市价单,所以他这里混在一起了
    struct Trade {
        //----------------------------------------------
        //Pack:64+160+8+8+16
        //uint256 tradeNumber;
        uint64 tradeNumber;
        address who;
        //uint256 state;
        uint8 state;
        //uint256 tradeType;
        uint8 tradeType;
        //uint256 pairNumber;
        uint16 pairCurrencyNumber;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:16+8+8+160+64

        //冗余
        uint16 pairNumber;
        //Pack:8+8+160+64+16128+32+32+32+32
        bool long;                   //看涨
        //uint256 leverage;              //几倍杠杆
        uint8 leverage;              //几倍杠杆
        address currency;               //何种货币

        //0 for not asking
        //uint256 orderNumber;                    //if asking a price order
        uint64 orderNumber;                    //if asking a price order
        //----------------------------------------------

        //----------------------------------------------
        //Pack:32+24+64+64+8+64
        //===================common部分===============
        //uint256 lastStateUpdateTimestamp;//
        uint32 lastStateUpdateTimestamp;//

        //uint256 slippagePercentIn10;                      //1_0400000000 1.04% 滑点似乎是滑点
        uint24 slippageFactorInExtraPoint;                //10400 0.01_0400 1.04%     1000000 -> 1.00_0000 100%
        //===================开仓请求部分===============
        //The initial position of the token: This will be 0 always on opening.
        //If you look at an already open trade it will show you the value of GNS used to open.
        //uint256 initialPosToken;       // 1e18 0？
        //uint256 desiredTp;                    // PRECISION 止盈 247661_1500000000 最大900% 可以填0, 会自动计算
        uint64 desiredTp;                    // PRECISION 止盈 247661_1500000000 最大900% 可以填0, 会自动计算
        //uint256 desiredSl;                    // PRECISION 止损 未设定  0, 可以填0, 表示不需要止损, 只要等待清仓就可以了
        uint64 desiredSl;                    // PRECISION 止损 未设定  0, 可以填0, 表示不需要止损, 只要等待清仓就可以了
        bool desiredIsSlSet;
        //uint256 desiredOpenPrice;             // PRECISION 开仓价格 45029_3000000000  这里是btc的价格  market已经包含了spread了?
        uint64 desiredOpenPrice;             // PRECISION 开仓价格 45029_3000000000  这里是btc的价格  market已经包含了spread了?
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        //uint256 desiredPositionInCurrency;//in currency       // 1e18  抵押物,仓位,本金,也就是最小的1500
        uint128 desiredPositionInCurrency;//in currency       // 1e18  抵押物,仓位,本金,也就是最小的1500

        //===================持仓部分(开完仓了)===============

        //uint256 openPositionInCurrency;//in currency       // 1e18  抵押物,仓位,本金,也就是最小的1500
        uint128 openPositionInCurrency;//in currency       // 1e18  抵押物,仓位,本金,也就是最小的1500
        //----------------------------------------------

        //----------------------------------------------
        //Pack:64+64+128
        //uint256 openPrice;                            //实际的开仓价
        uint64 openPrice;                            //实际的开仓价
        //uint256 openD3xPriceInCurrency;
        uint64 openD3xPriceInCurrency;

        //accFeePerOI
        //uint256 accFeePaid;
        uint128 accFeePaid;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:32+160+32+32
        //uint256 accFeePaidTimestamp;
        uint32 accFeePaidTimestamp;

        //只有一次机会触发 仅针对openLimit
        address openLimitTrigger;
        //for OI window
        //uint256 pairCurrencyOIWindowId;
        uint32 pairCurrencyOIWindowId;

        uint32 reserved32;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:64+64+8+32+64+24
        //==持仓时就可以追加关仓(tp,sl)的参数
        //uint256 tp;//永远被设定了值  是价格   也可以被update成0
        uint64 tp;//永远被设定了值  是价格   也可以被update成0
        //uint256 sl;//可能为0,没有被设定,这样只有清仓了
        uint64 sl;//可能为0,没有被设定,这样只有清仓了
        bool isSlSet;

        //============
        //uint256 closeTimestamp;
        uint32 closeTimestamp;
        //uint256 closePrice;
        uint64 closePrice;
        uint24 reserved24;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:256
        bytes cancelReason;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128*10  5个256
        //uint256 closeReturnPositionInCurrency;
        uint128 closeReturnPositionInCurrency;

        //============ 所有费用记录
        uint128 openGovFee;
        uint128 openStakingFee;
        uint128 openTradeFee;
        uint128 openLimitTriggerFee;
        uint128 openOracleFee;

        uint128 closeTradeFee;
        uint128 closeVaultFee;
        uint128 closeStakingFee;
        uint128 closeOracleFee;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+32+32+32+32
        uint128 borrowingFee;

        //==============
        //用于limit pending
        //设定:TRADE_STATE_LIMIT_PENDING
        //使用:服务器使用
        //功能:记录了用户limit order挂单的时间
        //uint256 limitPendingTimestamp;
        uint32 limitPendingTimestamp;
        //挂单等待oracle喂价的时间
        //设定:TRADE_STATE_MARKET_OPENING  TRADE_STATE_LIMIT_OPENING
        //使用:服务器使用
        //功能:对于市价单,记录了用户open的时间,对于限价单,记录了服务器触发的时间
        //uint256 openingTimestamp;
        uint32 openingTimestamp;
        //开单时间戳，用于清
        //设定:首次进入TRADE_STATE_LIVE
        //使用:TRADE_STATE_LIMIT_LIQ_CLOSING
        //uint256 createTimestamp;
        uint32 createTimestamp;
        //用来标记tp的时间
        //设定:首次进入TRADE_STATE_LIVE 更新TP
        //使用:TRADE_STATE_LIMIT_TP_CLOSING
        //uint256 tpTimestamp;
        uint32 tpTimestamp;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:32+32+192
        //用来标记sl的时间
        //设定:首次进入TRADE_STATE_LIVE 更新SL
        //使用:TRADE_STATE_LIMIT_SL_CLOSING
        //uint256 slTimestamp;
        uint32 slTimestamp;
        //用于关单
        //设定:每次TRADE_STATE_MARKET_CLOSING
        //使用:服务器使用
        //设定:关单失败后清楚这个数据,回到live状态时清除
        //uint256 closingTimestamp;
        uint32 closingTimestamp;

        uint192 reserved192;
        //----------------------------------------------

    }

    struct Order {
        //----------------------------------------------
        //Pack:64+160+32
        //uint256 orderNumber;
        uint64 orderNumber;
        address who;
        //uint256 timestamp;
        uint32 timestamp;
        //----------------------------------------------

        //仅保存 用于chainlink
        //因为不走chainlink,所以把参数留在这里
        bytes32 job;
        bytes32 from;
        bytes32 to;

        //----------------------------------------------
        //Pack:8+64+8+32+32+32+8+72
        //uint256 orderType;
        uint8 orderType;
        //uint256 tradeNumber;
        uint64 tradeNumber;
        //uint256 state;
        uint8 state;

        //uint256 fromPriceTimestamp;
        uint32 fromPriceTimestamp;
        //触发limit的时候,由触发服务器指定一个时间段,方便喂价服务器操作

        //触发器"透传"给喂价器的参数,方便缩小范围查询
        //uint256 fromTimestamp;
        uint32 fromTimestamp;
        //uint256 toTimestamp;
        uint32 toTimestamp;

        //uint256 threshold;
        uint8 threshold;

        uint72 reserved72;
        //----------------------------------------------

        //----------------------------------------------
        //Pack:128+128
        uint128 oracleFeePerSupplier;
        uint128 reserved128;
        //----------------------------------------------

        //temporally this is fake for self usage
        bytes32[] chainlinkRequestId;

        //实际的有效报价人
        address[] supplier;

        //单一报价
        //uint256[] spotPrice;
        uint64[] spotPrice;
        //蜡烛报价
        CandlePrice[] candlePrice;

        //----------------------------------------------
        //Pack:64+{64+64+64}

        //0 for not set
        //uint256 medianSpotPrice;
        uint64 medianSpotPrice;
        //0 for not set
        CandlePrice medianCandlePrice;
        //----------------------------------------------

        //如果回调错误, 记录可能的错误信息
        bytes orderFinishError;

    }

    struct Person {
        //uint256 pendingPriceOrderAmount;
        uint8 pendingPriceOrderAmount;
    }

    struct PersonCurrency {
        //uint256 lastFaucetTimstamp;
        uint32 lastFaucetTimestamp;
    }
    //开,关单的时候记录
    //需要被"窗口"读取后,用于计算动态价差
    struct PairCurrencyOIWindow {
        uint128 long; // 1e18 (DAI)
        uint128 short; // 1e18 (DAI)
    }

    //
    struct CandlePrice {
        //uint256 open;
        //uint256 high;
        //uint256 low;
        uint64 open;
        uint64 high;
        uint64 low;
    }

    //limit open
    struct Trigger {
        uint128 cumulativeOpenLimitTriggerFee;
        uint128 openLimitTriggerFee;

        //uint256 cumulativeOpenLimitTriggerTime;
        uint32 cumulativeOpenLimitTriggerCount;
    }

    //oracle fee feeder
    struct Supplier {

        uint128 cumulativeOracleFee;
        uint128 oracleFee;

        //uint256 cumulativeSupplyTime;
        uint32 cumulativeSupplyCount;
    }

    struct OpenTradeRequest {
        //uint256 pairNumber;
        uint16 pairCurrencyNumber;
        bool long;                   //看涨
        //uint256 leverage;              //几倍杠杆
        uint8 leverage;              //几倍杠杆
        //uint256 tradeType;
        uint8 tradeType;
        //==================================
        //uint256 slippageP;
        uint24 slippageFactorInExtraPoint;
        uint128 desiredPositionInCurrency;       // 1e18  抵押物,仓位,本金,也就是最小的1500
        //The initial position of the token: This will be 0 always on opening.
        //If you look at an already open trade it will show you the value of GNS used to open.
        //uint256 initialPosToken;       // 1e18 0？
        //uint256 desiredOpenPrice;             // PRECISION 开仓价格 45029_3000000000  这里是btc的价格  market已经包含了spread了?
        uint64 desiredOpenPrice;             // PRECISION 开仓价格 45029_3000000000  这里是btc的价格  market已经包含了spread了?
        //uint256 desiredTp;                    // PRECISION 止盈 247661_1500000000 900%  请求时可以填0,但是会计算出止盈
        uint64 desiredTp;                    // PRECISION 止盈 247661_1500000000 900%  请求时可以填0,但是会计算出止盈
        //uint256 desiredSl;                    // PRECISION 止损 未设定  0                请求时可以填0,认为long的止损价就为0
        uint64 desiredSl;                    // PRECISION 止损 未设定  0                请求时可以填0,认为long的止损价就为0
        bool desiredIsSlSet;                  //是否设定Sl

    }

    struct FinishOpenTradeParam {
        uint128 openPositionInCurrency;
        uint128 leveragedPositionInCurrency;
        uint128 openGovFee;
        uint128 openStakingFee;
        uint128 openTradeFee;
        uint128 openLimitTriggerFee;
        uint128 openOracleFee;
        address currency;
    }

    struct FinishCloseTradeParam {
        uint128 leveragedPositionInCurrency;

        uint128 borrowingFee;
        uint128 closeTradeFee;
        uint128 closeVaultFee;
        uint128 closeStakingFee;
        uint128 closeOracleFee;

        uint128 leftInOpenTradeAnyMix;
        uint128 closeReturnPositionInCurrency;
    }

    struct LimitTradeTriggerRequest {
        //uint256 tradeNumber;
        uint64 tradeNumber;
        //uint256 triggerType;
        uint8 triggerType;
        //uint256 fromTimestamp;
        uint32 fromTimestamp;
        //uint256 toTimestamp;
        uint32 toTimestamp;
    }

    struct SetPairRequest {

        //uint256 pairNumber;
        uint16 pairNumber;

        bytes32 from;
        bytes32 to;
        //uint256 spreadPercentIn10;                    // PRECISION 静态价差 btc,eth 400000000 0.04, 其他为0   0.04%
        uint24 spreadFactorInExtraPoint;               // PRECISION 静态价差 btc,eth 400000000 0.04, 其他为0   0.04%
        uint8 feedPriceMultiplyDecimal;
        uint8 feedPriceDivideDecimal;

        address feed1;
        address feed2;
        //uint256 feedCalculation;
        uint8 feedCalculation;
        //uint256 maxDeviationPercentIn10;              //10_0000000000 10 10%
        uint24 maxDeviationFactorInExtraPoint;         //100000 -> 0.10_0000 -> 10%

        //=====================
        //bytes32 accessType;
        uint8 accessType;
        uint8 pricePrintDecimal;

    }

    struct SetPairCurrencyRequest {

        uint16 pairCurrencyNumber;
        //-----
        uint16 pairNumber;
        address currency;

        uint128 minLeveragedPositionInCurrency;
        uint128 maxLeveragedPositionInCurrency;

        uint8 minLeverage;
        uint8 maxLeverage;

        uint24 openGovFeeFactorInExtraPoint;
        uint24 openStakingFeeFactorInExtraPoint;
        uint24 openLimitTriggerFeeFactorInExtraPoint;

        uint24 closeVaultFeeFactorInExtraPoint;
        uint24 closeStakingFeeFactorInExtraPoint;

        uint24 tradeFeeFactorInExtraPoint;
        uint24 oracleFeeFactorInExtraPoint;
        uint24 referralFeeFactorInExtraPoint;
    }

    struct SetPairCurrencyDepthRequest {
        uint16 pairCurrencyNumber;
        uint128 onePercentDepthAbove;
        uint128 onePercentDepthBelow;
    }

    struct SetBorrowingFeeRateRequest {
        uint16 pairCurrencyNumber;
        uint24 borrowingFeePerDayFactorInExtraPoint;
        uint128 maxOI;
    }

    struct GetActivePairCurrencyNestedResponse {
        uint16 pairCurrencyNumber;
        PairCurrency pairCurrency;

        uint16 pairNumber;
        Pair pair;

        address currency;
        Currency configCurrency;
        address vaultAddress;
    }

    //=====================
}
