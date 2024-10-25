// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameServiceRefLayout.sol";
import "../dependant/nameServiceRef/GenericNameServiceRefStorage.sol";

contract NameServiceRefStorage is NameServiceRefLayout, GenericNameServiceRefStorage {

    constructor (
        address nameService_
    )
    GenericNameServiceRefStorage(nameService_){

    }
}
