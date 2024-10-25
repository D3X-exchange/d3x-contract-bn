// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameServiceLayout.sol";
import "../dependant/nameService/GenericNameServiceStorage.sol";

contract NameServiceStorage is Proxy, NameServiceLayout, GenericNameServiceStorage {

    constructor (
        address owner_
    )
    Proxy(msg.sender)
    GenericNameServiceStorage(owner_){

    }
}
