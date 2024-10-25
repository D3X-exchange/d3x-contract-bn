// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../nameServiceRef/GenericNameServiceRefInterface.sol";
import "./VRFReceiverEvent.sol";

interface VRFReceiverInterface is GenericNameServiceRefInterface, VRFReceiverEvent {

    function rawFulfillRandomness(bytes32 requestId, bytes32 randomness) external;

}
