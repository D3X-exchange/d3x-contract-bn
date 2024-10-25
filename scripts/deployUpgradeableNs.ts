import * as hre from 'hardhat'
import {Contract,Signer} from "ethers";
import "@nomicfoundation/hardhat-ethers";

import {_deployContract, getContractAt, stringToBytes32} from './helper'
import {saveToFile} from "./save";
import {getAccount} from "./account";

const network = hre.network
const ethers = hre.ethers

export async function deployUpgradeableNs(
    logicBaseName: string,
    ns: Contract | null,
    saveName: string | null = null,
    nameServiceKeyOfDelegationLogic: string,
    proxySysAdmin: string | null = null,
    ...args: Array<any>
):
    Promise<Contract> {

    const unit = ethers.WeiPerEther;

    let tx, dead = `0x000000000000000000000000000000000000dead`, save: Record<string, any> = {}

    console.log(`deployUpgradeableNs ${logicBaseName}, save to ${saveName?? logicBaseName}`);
    save.network = network.name


    let [{
        sysAdmin,
        operator,
    }] = await getAccount(save)

    let storageName = `${logicBaseName}Storage`
    let interfaceName = `${logicBaseName}Interface`

    /*    let logicNames = []

        if (logicCount == 1) {
            logicNames.push(`${logicBaseName}Logic`)
        } else {
            for (let i = 1; i <= logicCount; i++) {
                logicNames.push(`${logicBaseName}Logic${i}`)
            }
        }*/

    let nsAndOwner = []
    if (ns !== null) {
        nsAndOwner.push(await ns.getAddress())
    }
    nsAndOwner.push(await operator.getAddress())

    let {
        storage,
        storageApi,
        //logics
    } = await deployContractNsUpgradeable(
        sysAdmin,
        operator,//connected signer of storageApi
        {
            storageName: storageName,
            // logicNames: logicNames,
            interfaceName: interfaceName
        },
        ...args,
        stringToBytes32(nameServiceKeyOfDelegationLogic),
        proxySysAdmin ?? await sysAdmin.getAddress(),
        ...nsAndOwner,
    )

    save[`${logicBaseName}Storage`] = await storage.getAddress()

    /*if (logicCount == 1) {
        save[`${logicBaseName}Logic`] = logics[0].address
    } else {
        for (let i = 1; i <= logicCount; i++) {
            save[`${logicBaseName}Logic${i}`] = logics[i - 1].address
        }
    }*/

    await saveToFile(save, `${saveName ?? logicBaseName}`, false)

    console.log(`deployUpgradeableNs ${logicBaseName} done: ${await storage.getAddress()}`)

    return storageApi
}


export async function deployContractNsUpgradeable(
    sysAdmin: Signer,
    defaultSigner: Signer | null,
    {storageName, /*logicNames,*/ interfaceName}: {
        storageName: string,
        // logicNames: Array<string>,
        interfaceName: string,
    },
    //the last 4 items must be ns-key of logic contract, sysAdmin, ns-address and owner
    ...args: Array<any>
): Promise<{ storage: Contract, storageApi: Contract/*, logics: Array<Contract>*/ }> {

    /*if (logicNames.length == 0) {
        throw new Error(`deploy storage ${storageName} with no logics`)
    }*/


    let storage = await _deployContract(sysAdmin, storageName, ...args)

    console.log(`    deployContractNsUpgradeable, storage: ${storageName}`)


    /* let logics: Array<Contract> = []


    for (let logicName of logicNames) {

        let logicFactory = await ethers.getContractFactory(logicName);
        let logic = await logicFactory.connect(sysAdmin).deploy();
        await logic.deployTransaction.wait(1)
            await waitTx(logic.deployTransaction)

        console.log(`    deployContractUpgradeable, logic: ${logicName}`)


        logics.push(logic)
    }

    tx = await storage.connect(sysAdmin).sysAddDelegates(logics.map(item => item.address))
    await waitTx(tx)
    console.log(`    deployContractUpgradeable, add delegates`)*/

    if (!defaultSigner) {
        defaultSigner = sysAdmin
    }

    let storageApi = await getContractAt(defaultSigner, interfaceName, await storage.getAddress(),)

    return {
        storage,
        storageApi,
        //logics
    }
}
