// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyClusterLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

import "./GenericSafetyClusterType.sol";

abstract contract GenericSafetyClusterStorage is GenericSafetyClusterLayout, OwnableStorage, GenericNameServiceRefStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    constructor (
        address owner_
    )
    OwnableStorage(owner_)
        //    GenericNameServiceRefStorage(accessControl_)
    {

    }
}
