// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFReceiverLayout.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

//this is a combining module, can be combined with others
abstract contract VRFReceiverStorage is VRFReceiverLayout, GenericNameServiceRefStorage {

    constructor (
    )//    GenericNameServiceRefStorage(nameService_)
    {
    }
}
