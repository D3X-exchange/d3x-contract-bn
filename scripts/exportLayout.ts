import * as hre from 'hardhat'
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-storage-layout';

async function main() {
    await hre.storageLayout.export();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
