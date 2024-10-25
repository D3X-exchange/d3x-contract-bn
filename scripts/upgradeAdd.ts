import * as hre from 'hardhat'
import {Contract, isAddress} from "ethers";
import "@nomicfoundation/hardhat-ethers";

import {_deployContract, getContractAt, waitTx} from './helper'
import {saveToFile} from "./save";
import {getAccount} from "./account";


const network = hre.network
const ethers = hre.ethers

export async function upgradeAdd(logicName: string, storageAddress: string): Promise<Contract> {

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

    let storage = await getContractAt(sysAdmin, 'Proxy', storageAddress,)

    let newLogic = await _deployContract(sysAdmin, logicName)
    console.log(`newLogic ${logicName}: ${newLogic.address}`)

    tx = await storage.sysAddDelegates([await newLogic.getAddress()])
    await waitTx(tx)

    save.storage = await storage.getAddress()
    save.newLogic = await newLogic.getAddress()

    await saveToFile(save, `${logicName}`, true)

    console.log(`upgrade ${logicName} done`)

    return newLogic
}
