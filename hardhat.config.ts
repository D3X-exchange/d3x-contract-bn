import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as fs from 'fs'
import * as path from 'path'
// import 'hardhat-storage-layout';
import "hardhat-storage-layout-json";

const story4t_mnemonic = readMnemonic('./story4t.mnemonic');

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            accounts: {
                mnemonic: 'test test test test test test test test test test test junk',
                initialIndex: 0,
                path: "m/44'/60'/0'/0",
                count: 60,
                accountsBalance: "1000000000000000000000000000000000000",
            },
            throwOnTransactionFailures: true,
            throwOnCallFailures: true,
            allowUnlimitedContractSize: false,
            gas: 80000000,
            blockGasLimit: 80_000_000,
            gasPrice: 5000000000,

        },

        story4t: {
            url: "https://testnet.storyrpc.io", //https://testnet.storyscan.xyz
            chainId: 1513,
            // gasPrice: 22_100_000_000,
            //gasPrice: `auto`,
            accounts: {
                mnemonic: story4t_mnemonic,
                initialIndex: 0,
                path: "m/44'/60'/0'/0",
                count: 60,
            },
            //timeout: 20 * 1000,
            //gasMultiplier: 1.1
        },

    },
    etherscan: {
      //bsc
      apiKey: "AE38UNTESDQ6Y1G5AA9YKMNI33VP4T4ETR",
    },
    /*etherscan: {
      //arb
      apiKey: "7W4DGFFNKPSP55QF27P9K9749JH75TVJQ7",
    },*/
    solidity: {
        compilers: [
            /*{
              version: "0.4.26",
              settings: {
                optimizer: {
                  enabled: true,
                  runs: 200
                },
                    viaIR: true,
                outputSelection: {
                  "*": {
                    "*": ["storageLayout"],
                  },
                },
              }
            },
            {
              version: "0.5.16",
              settings: {
                optimizer: {
                  enabled: true,
                  runs: 200
                },
                    viaIR: true,
                outputSelection: {
                  "*": {
                    "*": ["storageLayout"],
                  },
                },
              }
            },
            {
              version: "0.6.6",
              settings: {
                optimizer: {
                  enabled: true,
                  runs: 200
                },
                    viaIR: true,
                outputSelection: {
                  "*": {
                    "*": ["storageLayout"],
                  },
                },
              }
            },
            {
              version: "0.6.12",
              settings: {
                optimizer: {
                  enabled: true,
                  runs: 200
                },
                    viaIR: true,
                outputSelection: {
                  "*": {
                    "*": ["storageLayout"],
                  },
                },
              }
            },
            {
              version: "0.7.4",
              settings: {
                optimizer: {
                  enabled: true,
                  runs: 200
                },
                    viaIR: true,
                outputSelection: {
                  "*": {
                    "*": ["storageLayout"],
                  },
                },
              }
            },*/
            {
                version: "0.8.23",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    },
                    viaIR: true,
                    outputSelection: {
                        "*": {
                            "*": ["storageLayout"],
                        },
                    },
                }
            },
        ]
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 0,
        bail: true,
        color: true,
        parallel: false,
    },
    typechain: {
        outDir: "generated",
        target: "ethers-v6",
        alwaysGenerateOverloads: false
    },
};

function readMnemonic(relativePath:string):string{
    const p = path.resolve(relativePath)
    if(fs.existsSync(p)){
        return fs.readFileSync(p).toString().trim();
    }else{
        console.log(`mnemonic: ${p.toString()} does not exist.`)
        return 'test test test test test test test test test test test junk'
    }
}

export default config;
