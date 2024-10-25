// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NameServiceType {

    //**************************

    //gtrade自带的owner和manager都是时间锁,并且名字和ns冲突
    //这里将manager重新定向成'manager',  ns.manager不在是合约了
    //这里将admin重新定向成'admin', 和sysAdmin没有关系
    //原有的sysAdmin -> proxy.sysAdmin不变
    //原有的operator -> ownable.owner不变

    //manager和admin都用于管理合约,  应该都要替换成operator
    //bytes32 constant S_Manager = "Manager";
    //bytes32 constant S_Admin = "Admin";

    //暂时废弃掉manager和admin

    //用于接收fund
    //bytes32 constant S_Gov = "Gov";
    //bytes32 constant S_Dev = "Dev";

    //bytes32 constant S_USDT = "USDT";

    //bytes32 constant S_LINK = "LINK";

    //LP Shares的锁仓NFT
    //bytes32 constant S_D3xShareNFT = "D3xShareNFT";
    //LP Shares的锁仓NFT的链上图片  与 D3xShareNFT 合并
    //bytes32 constant S_D3xShareNFTImage = "D3xShareNFTImage";
    //费用和相关参数的读写
    //bytes32 constant S_D3xConfig = "D3xConfig";
    //交易执行功能（预言机）
    //bytes32 constant S_D3xExchangeHandler = "D3xExchangeHandler";
    //交易执行功能
    //bytes32 constant S_D3xExchange = "D3xExchange";
    //质押相关功能
    //bytes32 constant S_D3xStaking = "D3xStaking";
    //预言机配置和奖励分发
    //bytes32 constant S_D3xOracles = "D3xOracles";
    //市场价位的拉取与计算
    //bytes32 constant S_D3xPricing = "D3xPricing";
    //用于标注LP份额比例的币和相关操作
    //bytes32 constant S_D3xShare = "D3xShare";
    //用于计算当前LP Shares的盈亏
    //bytes32 constant S_D3xSharePnL = "D3xSharePnL";
    //邀请机制和奖励配置
    //bytes32 constant S_D3xInvite = "D3xInvite";
    //交易对信息和配置
    //bytes32 constant S_D3xPair = "D3xPair";
    //交易对配置数据存储合约
    //bytes32 constant S_D3xPairData = "D3xPairData";
    //交易所订单和配置数据存储合约
    //bytes32 constant S_D3xExchangeData = "D3xExchangeData";
    //持有早期NFT的用户配置和奖励
    //bytes32 constant S_D3xBadge = "D3xBadge";
    //团队内部资金解锁
    //bytes32 constant S_D3xDevManager = "D3xDevManager";

    //
    //bytes32 constant S_ChainlinkPriceFeed = "ChainlinkPriceFeed";

    //Receive = pool to collect
    //Dispatch = pool to send
    //Mix = receive+dispatch

    //name regulation = BusinessUsage + [tokenName/Any] + receive/dispatch/mix
    bytes32 constant S_OpenTradeAnyMix = "OpenTradeAnyMix";

    //bytes32 constant S_Vault = "Vault";

    bytes32 constant S_OpenGovFeeAnyReceive = "OpenGovFeeAnyReceive";
    bytes32 constant S_StakingAnyReceive = "StakingAnyReceive";
    //for open
    bytes32 constant S_TriggerAnyReceive = "TriggerAnyReceive";

    bytes32 constant S_TradeFeeAnyReceive = "TradeFeeAnyReceive";
    bytes32 constant S_OracleAnyReceive = "OracleAnyReceive";

    bytes32 constant S_FaucetAnyDispatch = "FaucetAnyDispatch";
    //***************************************************************************************************

    bytes32 constant MULTIPLE_REGISTRY_UNKNOWN = "";

    bytes32 constant M_Server = "Server";

    //    bytes32 constant M_Pool = "Pool";

    //**************************


}
