// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../context/ContextLayout.sol";
import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";

abstract contract HEIP712Layout is ContextLayout {

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 internal _cachedDomainSeparator;
    uint256 internal _cachedChainId;
    address internal _cachedThis;

    bytes32 internal _hashedName;
    bytes32 internal _hashedVersion;

    ShortString internal _name712;
    ShortString internal _version712;
    string internal _nameFallback;
    string internal _versionFallback;

    mapping(address account => uint256) internal _nonces;

}
