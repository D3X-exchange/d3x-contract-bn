// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFReceiverLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "./VRFReceiverInterface.sol";

import "../vrfCenter/GenericVRFCenterInterface.sol";

contract VRFReceiverLogic is VRFReceiverLayout, GenericNameServiceRefLogic, VRFReceiverInterface {

    //vrf center will invoke this funcion in return of 'feedVrf'
    function rawFulfillRandomness(bytes32 requestId, bytes32 randomness) override external {
        require(msg.sender == vrfCenter(), "vrf client: call back is not vrf center");
        _fulfillRandomness(requestId, randomness);
    }

    function _fulfillRandomness(bytes32 requestId, bytes32 randomness) virtual internal {

    }
}
