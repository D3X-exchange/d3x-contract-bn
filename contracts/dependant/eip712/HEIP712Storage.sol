// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HEIP712Layout.sol";
import "../context/ContextStorage.sol";
import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";

import "./HEIP712Type.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
abstract contract HEIP712Storage is HEIP712Layout, ContextStorage {

    using ShortStrings for *;

    constructor (
        string memory name712,
        string memory version712
    ){
        _name712 = name712.toShortStringWithFallback(_nameFallback);
        _version712 = version712.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name712));
        _hashedVersion = keccak256(bytes(version712));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(HEIP712Type.TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }
}
