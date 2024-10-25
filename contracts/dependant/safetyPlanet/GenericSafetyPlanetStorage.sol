// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyPlanetLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";
import "./GenericSafetyPlanetType.sol";

abstract contract GenericSafetyPlanetStorage is GenericSafetyPlanetLayout, OwnableStorage, GenericNameServiceRefStorage {

    constructor (
        address owner_
    )
    OwnableStorage(owner_)
        //    GenericNameServiceRefStorage(accessControl_)
    {

    }
}
