// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkClientLayout.sol";
import "../dependant/ownable/OwnableStorage.sol";
import "../nameServiceRef/NameServiceRefStorage.sol";

import "./ChainlinkClientType.sol";

abstract contract ChainlinkClientStorage is ChainlinkClientLayout,
OwnableStorage,
NameServiceRefStorage {

    constructor (

    /*address nameService_,
    address owner_*/
    )
        /*OwnableStorage(owner_)
        NameServiceRefStorage(nameService_)*/{

    }
}
