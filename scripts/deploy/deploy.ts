import * as hre from 'hardhat'
import "@nomicfoundation/hardhat-ethers";
import {deployAll} from "./deployAll";


const network = hre.network
const ethers = hre.ethers

export async function main() {

    await deployAll()

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
