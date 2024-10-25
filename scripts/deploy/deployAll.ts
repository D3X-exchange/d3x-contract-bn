import * as hre from 'hardhat'
import "@nomicfoundation/hardhat-ethers";
import {getAccount} from "../account";
import {PopulatedTransaction} from "@ethersproject/contracts";
import {deployUpgradeable} from "../deployUpgradeable";
import {deployUpgradeableNs} from "../deployUpgradeableNs";
import {getContractAt, stringToBytes32, waitTx} from '../helper'
import {Contract} from "ethers";
import {deployNormal} from "../deployNormal";
import {setPairCommonParams} from "./setPairParam.config";


const network = hre.network
const ethers = hre.ethers

export async function deployAll(): Promise<Array<Contract>> {

    const unit = ethers.WeiPerEther;

    let tx, dead = `0x000000000000000000000000000000000000dead`, save: Record<string, any> = {}
    let pt: PopulatedTransaction
    let fullCallData: string

    console.log('network: ' + network.name);
    save.network = network.name

    let [{
        sysAdmin,
        operator,
        server,
        rootInviter,
    },
    ] = await getAccount(save, true)

    let usdt
    if (network.name == `hardhat` || network.name == `bsc4t` || network.name == `x14t` || network.name === `story4t`) {
        usdt = await deployNormal(operator, `TestUsdt`)
        //usdt = await getContractAt(operator, `TestUsdt`,`0xF25e83201Bf3D7121265b5C16Ec0165253A30442`)

    } else if (network.name == `x1`) {
        //没错 和polygonZK一样
        usdt = await getContractAt(operator, `IERC20`, `0x1e4a5963abfd975d8c9021ce480b42188849d41d`,)

    } else if (network.name == `bsc`) {
        //busd
        usdt = await getContractAt(operator, `IERC20`, `0x55d398326f99059fF775485246999027B3197955`,)

    } else {
        throw new Error("unknown network")
    }

    let nameService = await deployUpgradeable(`NameService`, 1, null)
    //let nameService = await getContractAt(operator,`NameServiceInterface`, ``)

    let manager = await deployUpgradeable(`D3xManager`, 7, nameService)
    //let manager = await getContractAt(operator,`D3xManagerInterface`, ``)

    let safetyBoxLogic = await deployNormal(sysAdmin, `SafetyBoxLogic`)
    //let safetyBoxLogic = await getContractAt(operator, `SafetyBoxLogic`,``)

    let usdtAddress = await usdt.getAddress()

    let openTradeAnyMix = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `OpenTradeAnyMix`,
        `SafetyBoxLogic`
    )
    //let openTradeAnyMix = await getContractAt(operator,`SafetyBoxInterface`,``)

    let openGovFeeAnyReceive = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `OpenGovFeeAnyReceive`,
        `SafetyBoxLogic`
    )
    //let openGovFeeAnyReceive = await getContractAt(operator,`SafetyBoxInterface`,``)

    let stakingAnyReceive = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `StakingAnyReceive`,
        `SafetyBoxLogic`
    )
    //let stakingAnyReceive = await getContractAt(operator,`SafetyBoxInterface`,``)

    let triggerAnyReceive = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `TriggerAnyReceive`,
        `SafetyBoxLogic`
    )
    //let triggerAnyReceive = await getContractAt(operator,`SafetyBoxInterface`,``)

    let tradeFeeAnyReceive = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `TradeFeeAnyReceive`,
        `SafetyBoxLogic`
    )
    //let tradeFeeAnyReceive = await getContractAt(operator,`SafetyBoxInterface`,``)

    let oracleAnyReceive = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `OracleAnyReceive`,
        `SafetyBoxLogic`
    )
    //let oracleAnyReceive = await getContractAt(operator,`SafetyBoxInterface`,``)

    let pUsdtName = `pUsdt`
    if (network.name == `hardhat` || network.name == `bsc4t` || network.name == `x14t` || network.name == `story4t`) {
        pUsdtName = `pTestUsdt`
    }
    let pUsdt = await deployUpgradeable(
        `D3xVault`,
        1,
        nameService,
        `pUsdt`,
        await usdt.getAddress(),//asset address
        pUsdtName,//name
        pUsdtName,//symbol
    )
    //let pUsdt = await getContractAt(operator,`D3xVaultInterface`,``)

    let multicall3 = await deployNormal(sysAdmin, `Multicall3`)
    //let multicall3 = await getContractAt(operator,`Multicall3`,``)

    let faucetAnyDispatch = await deployUpgradeableNs(
        `SafetyBox`,
        nameService,
        `FaucetAnyDispatch`,
        `SafetyBoxLogic`
    )
    //let faucetAnyDispatch = await getContractAt(operator,`SafetyBoxInterface`,``)

    let singleParam: Array<{
        name: string,
        record: {
            addr: string,
            trusted: boolean
        },
        enable: boolean
    }> = [
        {
            name: stringToBytes32(`SafetyBoxLogic`),
            record: {
                addr: await safetyBoxLogic.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`Manager`),
            record: {
                addr: await manager.getAddress(),
                trusted: true,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`Multicall3`),
            record: {
                addr: await multicall3.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`OpenTradeAnyMix`),
            record: {
                addr: await openTradeAnyMix.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`OpenGovFeeAnyReceive`),
            record: {
                addr: await openGovFeeAnyReceive.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`StakingAnyReceive`),
            record: {
                addr: await stakingAnyReceive.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`TriggerAnyReceive`),
            record: {
                addr: await triggerAnyReceive.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`TradeFeeAnyReceive`),
            record: {
                addr: await tradeFeeAnyReceive.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`OracleAnyReceive`),
            record: {
                addr: await oracleAnyReceive.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`pUsdt`),
            record: {
                addr: await pUsdt.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        {
            name: stringToBytes32(`FaucetAnyDispatch`),
            record: {
                addr: await faucetAnyDispatch.getAddress(),
                trusted: false,
            },
            enable: true,
        },
        //========================
    ]

    let multiParam: Array<{
        name: string,
        records: Array<{
            addr: string,
            trusted: boolean
        }>,
        enable: boolean
    }> = [
        {
            name: stringToBytes32(`Server`),
            records: [{
                addr: await server.getAddress(),
                trusted: true,
            }],
            enable: true,
        },
    ]

    tx = await nameService.setEntries(
        singleParam,
        multiParam,
    )
    await waitTx(tx)
    console.log(`nameService.setMultipleEntries`)

    let isFaucetSupported;
    if (network.name == `hardhat`) {
        isFaucetSupported = true
    } else if (network.name == `x14t` || network.name == `bsc4t` || network.name === `story4t`) {
        isFaucetSupported = true
    } else if (network.name == `x1` || network.name == `bsc`) {
        isFaucetSupported = false
    } else {
        throw new Error("feed1 unknown network")
    }

    {

        tx = await manager.setGlobalConfig(
            {
                enableNewTrade: true,
                enableWriteFunction: true,

                maxTradePerPairCurrency: 3,
                maxConcurrentPriceOrder: 5,

                //maxNegativePnlOnOpenIn10 -> maxNegativePnlOnOpenWith10 少了10个0
                //maxNegativePnlOnOpenWith10: 40 * 1000, //这是改过后的值
                maxNegativePnlOnOpenWith10: 40, //我们随便设定一个

                nodePriceThreshold: 1,
                //marketOrdersTimeout: 1 * MINUTE,
                marketOrdersTimeoutForMinute: 5,

                //priceImpactPercentIn10 -> priceImpactRateInExtraPoint, 少了4个0
                oiStartTimestamp: 1709568000,//2024-03-05 00:00:00
                oiWindowsDuration: 7200,//2小时
                oiWindowsCount: 2,
                isFaucetSupported: isFaucetSupported,

                reserved104: 0,
            }
        )
        await waitTx(tx)
        console.log(`manager.setGlobalConfig`)

        console.log(`usdt decimal ${await usdt.decimals()}`)
        tx = await manager.setCurrency(
            await usdt.getAddress(),
            {
                vaultName: stringToBytes32(`pUsdt`),
                decimal: await usdt.decimals()
            }
        )
        await waitTx(tx)
        console.log(`manager.setCurrency`)

        let setPairParam
        let setPairParamSamePart = {
            maxDeviationFactorInExtraPoint: 100000, //10_0000000000 10 10%
            spreadFactorInExtraPoint: 400,               // PRECISION 静态价差 btc,eth 400000000 0.04, 其他为0   0.04%
            feed2: ethers.ZeroAddress,
            feedCalculation: 1,
        }
        if (network.name == `hardhat`) {
            setPairParam = setPairCommonParams.hardhatParam
        } else if (network.name == `story4t`) {
            setPairParam = setPairCommonParams.story4tParam
        } else {
            throw new Error("feed1 unknown network")
        }

        setPairParam = setPairParam.map(item => ({
            pairNumber: item.pairNumber,
            from: stringToBytes32(item.from),
            to: stringToBytes32(item.to),
            feed1: item.feed1,
            accessType: item.accessType,
            pricePrintDecimal: item.pricePrintDecimal,
            feedPriceMultiplyDecimal: item.feedPriceMultiplyDecimal,
            feedPriceDivideDecimal: item.feedPriceDivideDecimal,
            ...setPairParamSamePart,
        }))

        tx = await manager.setPair(
            setPairParam
        )
        await waitTx(tx)
        console.log(`manager.setPair`)

        tx = await manager.setPairCurrency(
            setPairParam.map(item => ({
                pairCurrencyNumber: item.pairNumber,//正好一对一

                pairNumber: item.pairNumber,
                currency: usdtAddress,

                // minLeveragedPositionInCurrency: unit * 5n,
                // maxLeveragedPositionInCurrency: unit * 1_000_000_000n,
                minLeveragedPositionInCurrency: unit * 5n,
                maxLeveragedPositionInCurrency: unit * 100n,
                minLeverage: 2,
                maxLeverage: 150,

                openGovFeeFactorInExtraPoint: 300, //0.03 %
                openStakingFeeFactorInExtraPoint: 300, //0.03 %
                openLimitTriggerFeeFactorInExtraPoint: 500, //0.005 %

                //清仓除外
                closeVaultFeeFactorInExtraPoint: 300, //0.03 %
                closeStakingFeeFactorInExtraPoint: 300, //0.03 %

                tradeFeeFactorInExtraPoint: 200,  //0.02 %
                oracleFeeFactorInExtraPoint: 50, //0.005 %

                referralFeeFactorInExtraPoint: 100,
            }))
        )
        await waitTx(tx)
        console.log(`manager.setPairCurrency`)

        tx = await manager.setBorrowingFeeRate(
            setPairParam.map(item => ({
                pairCurrencyNumber: item.pairNumber,//正好一对一
                //币安是每天0.003% 也就是0.00003/86400每秒
                borrowingFeePerDayFactorInExtraPoint: 30,//30 0.00003,  0.003%
                maxOI: unit * 1_000_000_000n
            }))
        )
        await waitTx(tx)
        console.log(`manager.setBorrowingFeeRate`)

        tx = await manager.setActivePairCurrency(
            setPairParam.map(item => item.pairNumber).flat(),
            [],
        )
        await waitTx(tx)
        console.log(`manager.setActivePairCurrency`)

        //
        tx = await manager.setSupportedSupplier(
            [
                await server.getAddress()
            ]
        )
        await waitTx(tx)
        console.log(`manager.setSupportedSupplier`)


        tx = await manager.setSupportedLimitTrigger(
            [
                await server.getAddress()
            ]
        )
        await waitTx(tx)
        console.log(`manager.setSupportedLimitTrigger`)

        //这些是测试的usdt test
        if (network.name == `hardhat` || network.name == `story4t`) {

            {
                //存股份
                tx = await usdt.approve(await pUsdt.getAddress(), ethers.MaxUint256)
                await waitTx(tx)
                console.log(`usdt.approve`)

                tx = await pUsdt.deposit(unit * 1_000_000n, await operator.getAddress())
                await waitTx(tx)
                console.log(`pUsdt.deposit`)
            }
            {
                //打水龙头
                tx = await usdt.transfer(await faucetAnyDispatch.getAddress(), unit * 1_000_000n)
                await waitTx(tx)
                console.log(`testUsdt.transfer`)
            }
        }

    }

    return [nameService, manager, usdt]

}
