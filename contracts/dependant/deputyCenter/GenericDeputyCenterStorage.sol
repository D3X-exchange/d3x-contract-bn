// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericDeputyCenterLayout.sol";
import "../ownable/OwnableStorage.sol";
import "../nameServiceRef/GenericNameServiceRefStorage.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
contract GenericDeputyCenterStorage is GenericDeputyCenterLayout, OwnableStorage, GenericNameServiceRefStorage {

    constructor (
        address nameService_,
        address owner_
    )
    OwnableStorage(owner_)
    GenericNameServiceRefStorage(nameService_)
    {

    }
}
