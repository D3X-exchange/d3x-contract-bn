// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFRefLayout.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

//this is a combining module, can be combined with others
abstract contract VRFRefStorage is VRFRefLayout, GenericNameServiceRefStorage {

    constructor (
    )//    GenericNameServiceRefStorage(nameService_)
    {
    }
}
