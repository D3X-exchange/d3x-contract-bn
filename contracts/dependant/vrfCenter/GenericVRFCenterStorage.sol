// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericVRFCenterLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
abstract contract GenericVRFCenterStorage is GenericVRFCenterLayout, OwnableStorage, GenericNameServiceRefStorage {

    constructor (
        address owner_
    )
    OwnableStorage(owner_)
        //    GenericNameServiceRefStorage(nameService_)
    {
    }
}
