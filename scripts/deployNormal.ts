import * as hre from 'hardhat'
import {Contract,Signer} from "ethers";
import "@nomicfoundation/hardhat-ethers";

import {_deployContract, getContractAt, waitTx} from './helper'
import {saveToFile} from "./save";
import {getAccount} from "./account";

const network = hre.network
const ethers = hre.ethers

export async function deployNormal(
    signer: Signer,
    factoryPath: string,
    ...args: Array<any>
): Promise<Contract> {

    let tx, dead = `0x000000000000000000000000000000000000dead`, save: Record<string, any> = {}

    console.log(`deployNormal ${factoryPath}`);
    save.network = network.name


    const deployedContract = await _deployContract(signer, factoryPath, ...args)

    save[`${factoryPath}`] = await deployedContract.getAddress()
    await saveToFile(save, `${factoryPath}`, false)

    console.log(`deployNormal ${factoryPath} done: ${await deployedContract.getAddress()}`);

    return deployedContract
}
