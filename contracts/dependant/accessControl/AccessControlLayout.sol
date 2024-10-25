// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableLayout.sol";

abstract contract AccessControlLayout is OwnableLayout {

    //privilege overrides block
    mapping(address => bool) _privilegeList;
    mapping(address => bool) _blockList;

}
