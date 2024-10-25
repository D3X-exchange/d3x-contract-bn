import * as fs from "fs";
import * as hre from 'hardhat'
import * as path from "path";

const network = hre.network

export async function saveToFile(obj: Record<string, any>, name: string, upgrade: boolean) {
    if (name === null || name === undefined || name.length === 0) {
        name = ''
    } else {
        name = name + '.'
    }

    let deploymentsDirName = 'deployments'

    if (!fs.existsSync(path.resolve(deploymentsDirName))) {
        fs.mkdirSync(path.resolve(deploymentsDirName), 0o777)
    }

    let networkName = network.name
    if (networkName === "hardhat") {
        //skip save
        return
    }

    if (!fs.existsSync(path.resolve(deploymentsDirName, networkName))) {
        fs.mkdirSync(path.resolve(deploymentsDirName, networkName), 0o777)
    }

    let savePath
    if (upgrade) {
        savePath = path.resolve(deploymentsDirName, networkName, `upgrade`)
    } else {
        savePath = path.resolve(deploymentsDirName, networkName, `deploy`)
    }

    if (!fs.existsSync(savePath)) {
        fs.mkdirSync(savePath, 0o777)
    }

    let fileName = name + network.name + '.' + new Date().getTime() + '.json'

    fs.writeFileSync(
        path.resolve(savePath, fileName),
        JSON.stringify(obj, null, 2),
        {flag: 'w'}
    )
}
