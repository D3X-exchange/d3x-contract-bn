// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyClusterRefLayout.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

abstract contract GenericSafetyClusterRefStorage is GenericSafetyClusterRefLayout, GenericNameServiceRefStorage {

    constructor (
    )
        //    GenericNameServiceRefStorage(nameService_)
    {
    }
}
