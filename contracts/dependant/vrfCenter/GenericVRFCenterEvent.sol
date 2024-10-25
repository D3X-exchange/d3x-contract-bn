// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GenericVRFCenterEvent {

    event RequestVRF(bytes32 indexed requestId);

    event VerifyVRF(bytes32 indexed requestId, bytes32 randomness);

    event FeedVRF(bytes32 indexed requestId, bytes32 randomness);

    event StuffVRF(bytes32 indexed requestId, bytes32 randomness);

}
