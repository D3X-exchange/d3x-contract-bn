// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "../dependant/ownable/OwnableStorage.sol";
import "../nameServiceRef/NameServiceRefStorage.sol";
import "../chainlinkClient/ChainlinkClientStorage.sol";
import "../twapPriceGetter/TWAPPriceGetterStorage.sol";

import "./D3xManagerType.sol";

contract D3xManagerStorage is Proxy,
D3xManagerLayout,
OwnableStorage,
NameServiceRefStorage,
ChainlinkClientStorage,
TWAPPriceGetterStorage {

    constructor (

        address nameService_,
        address owner_
    )
    Proxy(msg.sender)
    OwnableStorage(owner_)
    NameServiceRefStorage(nameService_){

    }
}
