// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xTemplateLayout.sol";
import "../dependant/ownable/OwnableStorage.sol";
import "../nameServiceRef/NameServiceRefStorage.sol";

import "./D3xTemplateType.sol";

contract D3xTemplateStorage is Proxy,
D3xTemplateLayout,
OwnableStorage,
NameServiceRefStorage {

    constructor (

        address nameService_,
        address owner_
    )
    Proxy(msg.sender)
    OwnableStorage(owner_)
    NameServiceRefStorage(nameService_){

    }
}
