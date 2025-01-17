// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC721IMLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";
import "../reentrancy/ReentrancyStorage.sol";
import "../erc721/HERC721Storage.sol";

import "./HERC721IMType.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
abstract contract HERC721IMStorage is HERC721IMLayout, OwnableStorage, GenericNameServiceRefStorage, ReentrancyStorage, HERC721Storage {

    constructor (
        HERC721IMType.ConstructorParam memory param,
        address owner_
    )
    OwnableStorage(owner_)
        // GenericNameServiceRefStorage(accessControl_)
    ReentrancyStorage()
    HERC721Storage(param.name, param.symbol, param.baseURI){
        _supportTransfer = param.supportTransfer;
        _supportMint = param.supportMint;
        _supportBurn = param.supportBurn;
    }
}
