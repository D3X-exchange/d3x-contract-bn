// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xVaultLayout.sol";
import "../dependant/ownable/OwnableStorage.sol";
import "../nameServiceRef/NameServiceRefStorage.sol";

import "./D3xVaultType.sol";
import "../dependant/erc4626/HERC4626Storage.sol";

contract D3xVaultStorage is Proxy,
D3xVaultLayout,
OwnableStorage,
NameServiceRefStorage,
HERC4626Storage {

    constructor (
        address asset_,
        string memory name_,
        string memory symbol_,

        address nameService_,
        address owner_
    )
    Proxy(msg.sender)
        //OwnableStorage(owner_)
    NameServiceRefStorage(nameService_)
    HERC4626Storage(
    asset_,
    HERC20IMType.ConstructorParam({
        name: name_,
        symbol: symbol_,
        cap: D3xVaultType.CAP,
        supportTransfer: true,
        supportMint: true,
        supportBurn: true
    }),
    owner_
    ){

    }
}
