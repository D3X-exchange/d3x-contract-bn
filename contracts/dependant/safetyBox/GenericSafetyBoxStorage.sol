// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyBoxLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

import "./GenericSafetyBoxType.sol";

abstract contract GenericSafetyBoxStorage is GenericSafetyBoxLayout, OwnableStorage, GenericNameServiceRefStorage {

    constructor (
        address owner_
    )
    OwnableStorage(owner_)
        //    GenericNameServiceRefStorage(accessControl_)
    {

    }
}
