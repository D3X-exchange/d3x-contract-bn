// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericNameServiceLayout.sol";
import "../accessControl/AccessControlStorage.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
//this module substitutes {AccessControlStorage}, must be combined with combining modules using {AccessControlStorage}
contract GenericNameServiceStorage is GenericNameServiceLayout, AccessControlStorage {

    constructor (
        address owner_
    )
    AccessControlStorage(owner_)
    {

    }
}
