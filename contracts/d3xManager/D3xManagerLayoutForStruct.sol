// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";
import "../chainlinkClient/ChainlinkClientLayout.sol";
import "../twapPriceGetter/TWAPPriceGetterLayout.sol";

import "./D3xManagerType.sol";

contract D3xManagerLayoutForStruct is
OwnableLayout,
NameServiceRefLayout,
ChainlinkClientLayout,
TWAPPriceGetterLayout {

    D3xManagerType.GlobalConfig internal _globalConfig_;

    D3xManagerType.Currency internal _currency_;

    D3xManagerType.Pair internal _pair_;

    D3xManagerType.PairCurrency internal _pairCurrency_;

    D3xManagerType.PairCurrencyOIWindow internal _pairCurrencyOIWindow_;

    D3xManagerType.Person internal _person_;

    D3xManagerType.PersonCurrency internal _personCurrency_;

    D3xManagerType.Trade internal _trade_;

    D3xManagerType.Order internal _order_;

    D3xManagerType.Supplier internal _supplier_;

    D3xManagerType.Trigger internal _trigger_;

    T internal _t_;

    struct T {
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
        //uint256 fromTimestamp;
        uint32 fromTimestamp;
        //uint256 toTimestamp;
        uint32 toTimestamp;

        //uint256 threshold;
        uint8 threshold;

        uint72 reserved72;
        //----------------------------------------------

        //temporally this is fake for self usage
        bytes32[] chainlinkRequestId;

        //实际的有效报价人
        address[] supplier;

        //----------------------------------------------
        //Pack:128+64+64
        uint128 oracleFeePerSupplier;
        //0 for not set
        //uint256 medianSpotPrice;
        uint64 medianSpotPrice;
        uint64 reserved64;

        //----------------------------------------------

        //----------------------------------------------
        //Pack:{64+64+64}+64
        D3xManagerType.CandlePrice medianCandlePrice;
        //----------------------------------------------

        //单一报价
        //uint256[] spotPrice;
        uint64[] spotPrice;
        //蜡烛报价
        D3xManagerType.CandlePrice[] candlePrice;

        //如果回调错误, 记录可能的错误信息
        bytes orderFinishError;

    }
}


