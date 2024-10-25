// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLayout.sol";

abstract contract GenericVRFCenterLayout is OwnableLayout, GenericNameServiceRefLayout {

    uint256 internal _vrfGlobalNonce;

    //fromContract => fromWho => reason => nonce
    mapping(address => mapping(address => mapping(bytes32 => uint256))) internal _vrfTriple;

    //alpha(requestId) => requested
    mapping(bytes32 => bool) internal _vrfAlphaString;
    //alpha(requestId) => randomness(betaString)
    mapping(bytes32 => bytes32) internal _vrfBetaString;

    //alpha(requestId) => address
    mapping(bytes32 => address) internal _vrfCallBack;

}
