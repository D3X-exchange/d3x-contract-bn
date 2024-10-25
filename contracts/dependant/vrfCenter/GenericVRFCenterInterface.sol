// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableInterface.sol";
import "../nameServiceRef/GenericNameServiceRefInterface.sol";

import "./GenericVRFCenterEvent.sol";
import "./GenericVRFCenterType.sol";

interface GenericVRFCenterInterface is OwnableInterface, GenericNameServiceRefInterface, GenericVRFCenterEvent {


    function requestVrf(address who, bytes32 reason) external returns (bytes32 requestId);

    //do remember to lock 'something' first
    function verifyVrf(
        GenericVRFCenterType.VerifyParam calldata param
    ) external returns (bytes32 randomness);

    function feedVrf(
        GenericVRFCenterType.VerifyParam calldata param
    ) external;

    function feedVrfs(
        GenericVRFCenterType.VerifyParam[] calldata params
    ) external;

    function stuffVrf(
        GenericVRFCenterType.StuffParam calldata param
    ) external;

    function stuffVrfs(
        GenericVRFCenterType.StuffParam[] calldata params
    ) external;

    function vrfAlphaString(bytes32 requestId) view external returns (bool);

    function vrfBetaString(bytes32 requestId) view external returns (bytes32);

    function publicKeyToAddress(uint256[2] memory publicKey) pure external returns (address);
}
