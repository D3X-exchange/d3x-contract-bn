// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFRefLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "./VRFRefInterface.sol";

import "../vrfCenter/GenericVRFCenterInterface.sol";

contract VRFRefLogic is VRFRefLayout, GenericNameServiceRefLogic, VRFRefInterface {

    //do remember to lock 'something' first
    function applyForVrf(address who, bytes32 reason) internal returns (bytes32 requestId){
        requestId = GenericVRFCenterInterface(vrfCenter()).requestVrf(who, reason);
        return requestId;
    }

    function vrfContinue(
        GenericVRFCenterType.VerifyParam memory param
    ) internal returns (bytes32 randomness){
        randomness = GenericVRFCenterInterface(vrfCenter()).verifyVrf(param);
        return randomness;
    }

}
