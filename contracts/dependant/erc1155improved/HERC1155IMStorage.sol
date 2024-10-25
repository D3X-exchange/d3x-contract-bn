// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC1155IMLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";
import "../reentrancy/ReentrancyStorage.sol";
import "../erc1155/HERC1155Storage.sol";

import "./HERC1155IMType.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
abstract contract HERC1155IMStorage is HERC1155IMLayout, OwnableStorage, GenericNameServiceRefStorage, ReentrancyStorage, HERC1155Storage {

    constructor (
        HERC1155IMType.ConstructorParam memory param,
        address owner_
    )
    OwnableStorage (owner_)
        //    AccessControlRefStorage(accessControl_)
    ReentrancyStorage()
    HERC1155Storage(param.uri){
        _supportTransfer = param.supportTransfer;
        _supportMint = param.supportMint;
        _supportBurn = param.supportBurn;
    }
}
