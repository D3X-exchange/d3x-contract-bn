import * as hre from 'hardhat'
import {Contract,Signer} from "ethers";
import "@nomicfoundation/hardhat-ethers";

import {_deployContract, getContractAt, waitTx} from './helper'
import {saveToFile} from "./save";
import {getAccount} from "./account";

const network = hre.network
const ethers = hre.ethers

export async function deployUpgradeable(logicBaseName: string, logicCount: number, ns: Contract | null, saveName: string | null = null, ...args: Array<any>): Promise<Contract> {

    const unit = ethers.WeiPerEther;

    let tx, dead = `0x000000000000000000000000000000000000dead`, save: Record<string, any> = {}

    console.log(`deployUpgradeable ${logicBaseName}, logic count: ${logicCount}, save to ${saveName?? logicBaseName}`);
    save.network = network.name


    let [{
        sysAdmin,
        operator,
    }] = await getAccount(save)

    let storageName = `${logicBaseName}Storage`
    let interfaceName = `${logicBaseName}Interface`

    let logicNames = []

    if (logicCount == 1) {
        logicNames.push(`${logicBaseName}Logic`)
    } else {
        for (let i = 1; i <= logicCount; i++) {
            logicNames.push(`${logicBaseName}Logic${i}`)
        }
    }


    let nsAndOwner = []
    if (ns !== null) {
        nsAndOwner.push(await ns.getAddress())
    }
    nsAndOwner.push(await operator.getAddress())

    let {
        storage,
        storageApi,
        logics
    } = await deployContractUpgradeable(
        sysAdmin,
        operator,//connected signer of storageApi
        {
            storageName: storageName,
            logicNames: logicNames,
            interfaceName: interfaceName
        },
        ...args,
        ...nsAndOwner,
    )

    save[`${logicBaseName}Storage`] = await storage.getAddress()

    if (logicCount == 1) {
        save[`${logicBaseName}Logic`] = await logics[0].getAddress()
    } else {
        for (let i = 1; i <= logicCount; i++) {
            save[`${logicBaseName}Logic${i}`] = await logics[i - 1].getAddress()
        }
    }

    await saveToFile(save, `${saveName ?? logicBaseName}`, false)

    console.log(`deployUpgradeable ${logicBaseName} done: ${await storage.getAddress()}`)


    return storageApi
}

async function deployContractUpgradeable(
    sysAdmin: Signer,
    defaultSigner: Signer | null,
    {storageName, logicNames, interfaceName}: {
        storageName: string,
        logicNames: Array<string>,
        interfaceName: string,
    },
    //the last 2 item must be ns-address and owner
    ...args: Array<any>
): Promise<{ storage: Contract, storageApi: Contract, logics: Array<Contract> }> {

    if (logicNames.length == 0) {
        throw new Error(`deployContractUpgradeable, storage ${storageName} with no logics`)
    }

    let tx

    // let storageFactory = await ethers.getContractFactory(storageName);
    // let storage = await storageFactory.connect(sysAdmin).deploy(...args);
    // await storage.waitForDeployment();

    let storage = await _deployContract(sysAdmin, storageName, ...args)

    console.log(`    deployContractUpgradeable, storage: ${storageName}`)


    let logics: Array<Contract> = []


    for (let logicName of logicNames) {

        // let logicFactory = await ethers.getContractFactory(logicName);
        // let logic = await logicFactory.connect(sysAdmin).deploy();
        // await logic.waitForDeployment();

        let logic = await _deployContract(sysAdmin, logicName)

        console.log(`    deployContractUpgradeable, logic: ${logicName}`)


        logics.push(logic)
    }

    let logicAddress: Array<string> = []
    for (let logic of logics) {
        logicAddress.push(await logic.getAddress())
    }

    tx = await storage.sysAddDelegates(logicAddress)
    await waitTx(tx)
    console.log(`    deployContractUpgradeable, adding delegates done`)

    if (!defaultSigner) {
        defaultSigner = sysAdmin
    }

    let storageApi = await getContractAt(defaultSigner, interfaceName, await storage.getAddress(),)

    return {
        storage,
        storageApi,
        logics
    }
}
