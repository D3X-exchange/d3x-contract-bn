import * as hre from 'hardhat'
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";
import {Signer} from "ethers";

const network = hre.network
const ethers = hre.ethers

export async function getAccount(save: Record<string, any> | null = null, print: boolean = false): Promise<[
    Record<string, Signer>
]> {

    let acc = await ethers.getSigners()
    let [
        sysAdmin,
        operator,
        server,
        rootInviter,

        test1,
        test2,
        test3,
        test4,

    ] = acc


    if (save !== null) {
        save.sysAdmin = sysAdmin.address
        save.operator = operator.address
        save.server = server.address
        save.rootInviter = rootInviter.address
    }

    if (print) {
        console.log(`sysAdmin: ${sysAdmin.address}`)
        console.log(`operator: ${operator.address}`)
        console.log(`server: ${server.address}`)
        console.log(`rootInviter: ${rootInviter.address}`)
        // console.log(`test1: ${test1.address}`)
        // console.log(`test2: ${test2.address}`)
        // console.log(`test3: ${test3.address}`)
        // console.log(`test4: ${test4.address}`)
    }

    //fully list the key and value
    return [
        {
            sysAdmin,
            operator,
            server,
            rootInviter,
            test1,
            test2,
            test3,
            test4,
        }
    ]
}
