// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafetyBoxLayout.sol";
import "../dependant/safetyBox/GenericSafetyBoxStorage.sol";
import "../nameServiceRef/NameServiceRefStorage.sol";

import "../dependant/proxy/NameServiceProxy.sol";
import "./SafetyBoxType.sol";

contract SafetyBoxStorage is NameServiceProxy, SafetyBoxLayout, GenericSafetyBoxStorage, NameServiceRefStorage {


    constructor (
        bytes32 nameServiceKey_,
        address sysAdmin_,
        address accessControl_,
        address owner_
    )
    NameServiceProxy(accessControl_, nameServiceKey_, sysAdmin_)
    GenericSafetyBoxStorage(owner_)
    NameServiceRefStorage(accessControl_)
    {

    }
}
