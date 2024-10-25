import * as hre from 'hardhat'
import "@nomicfoundation/hardhat-ethers";

import {
    Addressable,
    Contract,
    ContractTransactionReceipt,
    ContractTransactionResponse,
    EventLog,
    Signer,
    TransactionReceipt,
    TransactionResponse,
    UndecodedEventLog
} from "ethers";
import {rlp, toBuffer} from "ethereumjs-util";
import {padLeft} from "web3-utils";

import {saveToFile} from "./save";
import {getAccount} from "./account";

const ethers = hre.ethers
const abiEncoderPacked = ethers.solidityPacked
const network = hre.network

export async function _deployContract(
    signer: Signer,
    factoryPath: string,
    ...args: Array<any>
): Promise<Contract> {

    let tx, dead = `0x000000000000000000000000000000000000dead`, save: Record<string, any> = {}

    console.log(`        _deployContract ${factoryPath} doing`);
    save.network = network.name


    let [{
        sysAdmin,
        operator,
    }] = await getAccount(save)

    const factory = await ethers.getContractFactory(factoryPath);
    const x = factory.connect(signer)
    const baseContract = await x.deploy(...args);

    await baseContract.waitForDeployment();

    let contract = new Contract(
        await baseContract.getAddress(),
        baseContract.interface,
        signer
    )

    //await waitTx(baseContract)


    console.log(`        _deployContract ${factoryPath} done: ${await contract.getAddress()}`)

    return contract
}


/*export async function setDeputy(
    pt: PopulatedTransaction,
    signer: SignerWithAddress,
    uniqueNonce: BigNumber,
    dependUniqueNonce: BigNumber = ethers.constants.Zero,
    barrierNonce: BigNumber = ethers.constants.Zero,
    before: BigNumber = ethers.constants.Zero,
    value: BigNumber = ethers.constants.Zero,
    onlyDesignatedSender: boolean = false,
    designatedSender: string = ethers.constants.AddressZero,
): Promise<string> {
    let enabledCallData = pt.data!
    let to = pt.to!
    let chainId = (await ethers.provider.getNetwork()).chainId

    let toSign = abiEncoderPacked(
        [
            "bytes",//calldata
            "uint256",//real calldata length
            "address",//to
            "uint256",//chainId
            "uint256",//beforeTimeStamp
            "uint256",//uniqueNonce
            "uint256",//dependUniqueNonce
            "uint256",//barrierNonce
            "uint256",//value
            "bool",//onlyDesignatedSender
            "address",//designatedSender
            "address",//signer
        ],
        [
            enabledCallData,
            enabledCallData.length / 2 - 1,//the enabledCallData is start with 0x
            to,
            chainId,
            before,
            uniqueNonce,
            dependUniqueNonce,
            barrierNonce,
            value,
            onlyDesignatedSender,
            designatedSender,
            signer.address,
        ],
    )

    let digest = ethers.utils.keccak256(toSign)

    let sig = await signer.signMessage(ethers.utils.arrayify(digest))
    return toSign + sig.substring(2)
}*/

export async function waitTx(txResponse:  TransactionResponse): Promise<TransactionReceipt> {

    let txReceipt = await txResponse.wait(1)

    if (txReceipt === null) {
        throw new Error(`waitTx error`)
    }

    return txReceipt as TransactionReceipt
}

export async function waitCtx(cTxResponse: ContractTransactionResponse): Promise<ContractTransactionReceipt> {

    let ctxReceipt = await cTxResponse.wait(1)

    if (ctxReceipt === null) {
        throw new Error(`waitTx error`)
    }

    return ctxReceipt as ContractTransactionReceipt
}

export async function contractConnect(contract: Contract, signer: Signer): Promise<Contract> {

    return new Contract(
        await contract.getAddress(),
        contract.interface,
        signer
    )
}

export function getKnownEvent(txr: ContractTransactionReceipt): Array<EventLog> {

    let ret: Array<EventLog> = []

    for (let log of txr.logs) {
        if (log instanceof EventLog) {
            ret.push(log)
        } else if (log instanceof UndecodedEventLog) {

        }
    }
    return ret
}

export async function getContractAt(
    signer: Signer,
    name: string,
    address: string | Addressable,
): Promise<Contract> {

    return await ethers.getContractAt(name, address, signer)
}

export function sleep(time: number) {
    return new Promise((resolve) => setTimeout(resolve, time));
}

export function deadline() {
    // 30 minutes
    return Math.floor(new Date().getTime() / 1000) + 1800;
}

export function in5min() {
    // 5 minutes
    return Math.floor(new Date().getTime() / 1000) + 60 * 5;
}

export function in10min() {
    // 10 minutes
    return Math.floor(new Date().getTime() / 1000) + 60 * 10;
}

export function in30min() {
    // 30 minutes
    return Math.floor(new Date().getTime() / 1000) + 60 * 30;
}

export function justNow() {
    return Math.floor(new Date().getTime() / 1000);
}

export function stringToBytes32(input: string): string {
    // return ethers.utils.formatBytes32String(input)
    return ethers.encodeBytes32String(input)
}

export function bytes32ToString(input: string): string {
    return ethers.decodeBytes32String(input)
}

export function blockToRlpEncoded(block: any) {
    return rlp.encode([
        toBuffer(block.parentHash),
        toBuffer(block.sha3Uncles),
        toBuffer(block.miner),
        toBuffer(block.stateRoot),
        toBuffer(block.transactionsRoot),
        toBuffer(block.receiptsRoot),
        toBuffer(block.logsBloom),
        Number(block.difficulty),
        Number(block.number),
        Number(block.gasLimit),
        Number(block.gasUsed),
        Number(block.timestamp),
        toBuffer(block.extraData),
        toBuffer(block.mixHash),
        padLeft(block.nonce, 8),
    ])
}

export const SECOND = 1
export const MINUTE = 60 * SECOND
export const HOUR = 60 * MINUTE
export const DAY = 24 * HOUR
export const WEEK = 7 * DAY
export const MONTH = 30 * DAY
export const YEAR = 365 * DAY

let f = (input: any) => ethers.formatEther(input);
let p = (input: any) => ethers.parseEther(input);
let t = (input: string) => Date.parse(input) / 1000;
let ta = (input: string) => [Date.parse(input) / 1000];

export let setNextBlockTimestamp = async (timestamp: number | string) => {
    let ts
    if (typeof timestamp == `number`) {
        ts = timestamp
    } else {
        ts = t(timestamp)
    }

    await ethers.provider.send('evm_setNextBlockTimestamp', [ts])
}

export let increaseNextBlockTimestamp = async (timestamp: number) => {

    await ethers.provider.send('evm_increaseTime', [timestamp])
}

