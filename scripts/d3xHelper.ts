import * as hre from 'hardhat'
import "@nomicfoundation/hardhat-ethers";

const ethers = hre.ethers
const abiEncoderPacked = ethers.solidityPacked
const network = hre.network

//每"1"个(也就是decimal数量的token),产出  decimal*每秒利率个token
//最终计算为
//每"1"个 X/decimal
//产出  X/decimal*rate   (in18)
//最终  X/decimal*rate   ->  X*rate/decimal  这里可能会溢出,X为uint128,扩展到uint256可以解决问题
export function calcBorrowingFeeRatePerDay(decimal: number, ratePerDay: number): bigint {

    let one = 10 ** decimal
    let oneDayFee = Math.floor(one * ratePerDay)

    console.log(`calcBorrowingFeeRate:  ${BigInt(oneDayFee)}  ${ethers.formatEther(BigInt(oneDayFee))}`)
    return BigInt(oneDayFee)
}


// let fee = calcBorrowingFeeRatePerDay(18,0.003/100)
// console.log(`fee ${fee}  ${ethers.formatEther(fee)}`)

const ORDER_STATE_OPEN = 1n;
const ORDER_STATE_FINISHED = 2n;
const ORDER_STATE_CANCELLED = 3n;
const ORDER_STATE_FINISHED_WITH_ERROR = 4n;

export function orderState(orderState: bigint): string {
    if (orderState == ORDER_STATE_OPEN) {
        return `ORDER_STATE_OPEN`
    } else if (orderState == ORDER_STATE_FINISHED) {
        return `ORDER_STATE_FINISHED`
    } else if (orderState == ORDER_STATE_CANCELLED) {
        return `ORDER_STATE_CANCELLED`
    } else if (orderState == ORDER_STATE_FINISHED_WITH_ERROR) {
        return `ORDER_STATE_FINISHED_WITH_ERROR`
    } else {
        return `ORDER_STATE_ERROR!!!!!!!!!`
    }
}

//请求价格的原因
//for callback
const ORDER_TYPE_MARKET_OPEN = 1n;//原本是个市价单,需要喂价,喂价之后开仓
const ORDER_TYPE_MARKET_CLOSE = 2n;
//不区分limit和stop limit
const ORDER_TYPE_LIMIT_OPEN = 3n;
const ORDER_TYPE_LIMIT_CLOSE = 4n;

export function orderType(orderType: bigint): string {
    if (orderType == ORDER_TYPE_MARKET_OPEN) {
        return `ORDER_TYPE_MARKET_OPEN`
    } else if (orderType == ORDER_TYPE_MARKET_CLOSE) {
        return `ORDER_TYPE_MARKET_CLOSE`
    } else if (orderType == ORDER_TYPE_LIMIT_OPEN) {
        return `ORDER_TYPE_LIMIT_OPEN`
    } else if (orderType == ORDER_TYPE_LIMIT_CLOSE) {
        return `ORDER_TYPE_LIMIT_CLOSE`
    } else {
        return `ORDER_TYPE_ERROR!!!!!!!!!`
    }
}

const TRADER_TYPE_MARKET = 1n;
const TRADER_TYPE_LIMIT = 2n;
const TRADER_TYPE_STOP_LIMIT = 3n;

export function tradeType(tradeType: bigint): string {
    if (tradeType == TRADER_TYPE_MARKET) {
        return `TRADER_TYPE_MARKET`
    } else if (tradeType == TRADER_TYPE_LIMIT) {
        return `TRADER_TYPE_LIMIT`
    } else if (tradeType == TRADER_TYPE_STOP_LIMIT) {
        return `TRADER_TYPE_STOP_LIMIT`
    } else {
        return `TRADER_TYPE_ERROR!!!!!!!!!`
    }
}

const TRADE_STATE_EMPTY = 0n;//错误的仓位
const TRADE_STATE_LIVE = 1n;//正常的仓位

const TRADE_STATE_MARKET_OPENING = 2n;//正在请求price order

const TRADE_STATE_LIMIT_PENDING = 3n;//limit单子进入了深度,等待服务器触发
const TRADE_STATE_LIMIT_OPENING = 4n;//limit单子触发开单 也是trigger

//live的单子 需要服务器监听tp sl 和 liq

const TRADE_STATE_MARKET_CLOSING = 5n;//正在请求price order
const TRADE_STATE_LIMIT_TP_CLOSING = 6n;//单子触发limit tp 也是trigger
const TRADE_STATE_LIMIT_SL_CLOSING = 7n;//单子触发limit sl 也是trigger
const TRADE_STATE_LIMIT_LIQ_CLOSING = 8n;//单子触发limit liq 也是trigger

const TRADE_STATE_MARKET_CLOSED = 9n;//结束的单子

//cancel
const TRADE_STATE_LIMIT_CANCELLED = 10n;//limit单子进入了深度,但是取消了
//time out
const TRADE_STATE_MARKET_OPEN_TIMEOUT = 11n;//市价开单超时 或者callback有revert
const TRADE_STATE_LIMIT_OPEN_TIMEOUT = 12n;//限价开单超时  或者callback有revert

const TRADE_STATE_MARKET_OPEN_CANCELLED = 13n; //order失败,市价开单失败
const TRADE_STATE_LIMIT_OPEN_CANCELLED = 14n; //order失败,限价开单失败

const TRADE_STATE_LIMIT_TP_CLOSED = 15n;//tp关单结束
const TRADE_STATE_LIMIT_SL_CLOSED = 16n;//sl关单结束
const TRADE_STATE_LIMIT_LIQ_CLOSED = 17n;//tp关单结束

export function tradeState(tradeState: bigint): string {
    if (tradeState == TRADE_STATE_EMPTY) {
        return `TRADE_STATE_EMPTY`
    } else if (tradeState == TRADE_STATE_LIVE) {
        return `TRADE_STATE_LIVE`
    } else if (tradeState == TRADE_STATE_MARKET_OPENING) {
        return `TRADE_STATE_MARKET_OPENING`
    } else if (tradeState == TRADE_STATE_LIMIT_PENDING) {
        return `TRADE_STATE_LIMIT_PENDING`
    } else if (tradeState == TRADE_STATE_LIMIT_OPENING) {
        return `TRADE_STATE_LIMIT_OPENING`
    } else if (tradeState == TRADE_STATE_MARKET_CLOSING) {
        return `TRADE_STATE_MARKET_CLOSING`
    } else if (tradeState == TRADE_STATE_LIMIT_TP_CLOSING) {
        return `TRADE_STATE_LIMIT_TP_CLOSING`
    } else if (tradeState == TRADE_STATE_LIMIT_SL_CLOSING) {
        return `TRADE_STATE_LIMIT_SL_CLOSING`
    } else if (tradeState == TRADE_STATE_LIMIT_LIQ_CLOSING) {
        return `TRADE_STATE_LIMIT_LIQ_CLOSING`
    } else if (tradeState == TRADE_STATE_MARKET_CLOSED) {
        return `TRADE_STATE_MARKET_CLOSED`
    } else if (tradeState == TRADE_STATE_LIMIT_CANCELLED) {
        return `TRADE_STATE_LIMIT_CANCELLED`
    } else if (tradeState == TRADE_STATE_MARKET_OPEN_TIMEOUT) {
        return `TRADE_STATE_MARKET_OPEN_TIMEOUT`
    } else if (tradeState == TRADE_STATE_LIMIT_OPEN_TIMEOUT) {
        return `TRADE_STATE_LIMIT_OPEN_TIMEOUT`
    } else if (tradeState == TRADE_STATE_MARKET_OPEN_CANCELLED) {
        return `TRADE_STATE_MARKET_OPEN_CANCELLED`
    } else if (tradeState == TRADE_STATE_LIMIT_OPEN_CANCELLED) {
        return `TRADE_STATE_LIMIT_OPEN_CANCELLED`
    } else if (tradeState == TRADE_STATE_LIMIT_TP_CLOSED) {
        return `TRADE_STATE_LIMIT_TP_CLOSED`
    } else if (tradeState == TRADE_STATE_MARKET_OPEN_CANCELLED) {
        return `TRADE_STATE_MARKET_OPEN_CANCELLED`
    } else if (tradeState == TRADE_STATE_LIMIT_SL_CLOSED) {
        return `TRADE_STATE_LIMIT_SL_CLOSED`
    } else if (tradeState == TRADE_STATE_LIMIT_LIQ_CLOSED) {
        return `TRADE_STATE_LIMIT_LIQ_CLOSED`
    } else {
        return `TRADE_STATE_ERROR!!!!!!!!!`
    }
}

