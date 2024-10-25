// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../accessControl/AccessControlLayout.sol";

import "./GenericNameServiceType.sol";

abstract contract GenericNameServiceLayout is AccessControlLayout {

    EnumerableSet.Bytes32Set internal _singleKeys;
    //key => address
    mapping(bytes32 => GenericNameServiceType.AddressRecord) _singleRegistry;


    EnumerableSet.Bytes32Set internal _multipleKeys;
    //key => addresses
    mapping(bytes32 => EnumerableSet.AddressSet) _multipleKeyAddress;
    mapping(bytes32 => mapping(address => GenericNameServiceType.AddressRecord)) _multipleRegistry;

    EnumerableSet.Bytes32Set internal _envKeys;
    mapping(bytes32 => uint256) _envRegistry;
}
