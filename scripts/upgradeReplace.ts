import * as hre from 'hardhat'
import {Contract, isAddress} from "ethers";
import "@nomicfoundation/hardhat-ethers";

import {_deployContract, getContractAt, waitTx} from './helper'
import {saveToFile} from "./save";
import {getAccount} from "./account";


const network = hre.network
const ethers = hre.ethers

export async function upgradeReplace(logicName: string, storageAddress: string, oldAddress: string): Promise<Contract> {

    const unit = ethers.WeiPerEther;

    let tx, dead = `0x000000000000000000000000000000000000dead`, save: Record<string, any> = {}

    console.log('network: ' + network.name);
    save.network = network.name


    let [{
        sysAdmin,
        operator,
    }] = await getAccount(save)

    //caution!!!!!!!!!!

    if (!isAddress(storageAddress)) {
        throw new Error(`upgrade storageAddress ${storageAddress}`)
    }
    if (!isAddress(oldAddress)) {
        throw new Error(`upgrade oldAddress ${oldAddress}`)
    }


    let storage = await getContractAt(sysAdmin, 'Proxy', storageAddress,)

    let delegators: Array<any> = await storage.sysGetDelegateAddresses()

    if (!delegators.some(
        delegatorAddress =>
            oldAddress.toLowerCase() === delegatorAddress.toLowerCase()
    )) {
        throw Error(`old delegator ${oldAddress} is not found`)
    }

    const newLogic = await _deployContract(sysAdmin, logicName)
    console.log(`newLogic ${logicName}: ${await newLogic.getAddress()}`)

    tx = await storage.sysReplaceDelegates([oldAddress], [await newLogic.getAddress()])
    await waitTx(tx)

    save.storage = await storage.getAddress()
    save.oldLogic = oldAddress
    save.newLogic = await newLogic.getAddress()

    await saveToFile(save, `${logicName}`, true)

    console.log(`upgrade ${logicName} done`)

    return newLogic
}
