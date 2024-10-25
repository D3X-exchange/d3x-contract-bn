// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericNameServiceRefLayout.sol";
import "../accessControlRef/AccessControlRefLogic.sol";
import "./GenericNameServiceRefInterface.sol";

import "../nameService/GenericNameServiceInterface.sol";
import "../nameService/GenericNameServiceType.sol";

contract GenericNameServiceRefLogic is GenericNameServiceRefLayout, AccessControlRefLogic, GenericNameServiceRefInterface {

    function ns() view internal returns (GenericNameServiceInterface){
        require(_accessControl != address(0), "ns(): address 0");
        return GenericNameServiceInterface(_accessControl);
    }

    function nsUnsafe() view internal returns (GenericNameServiceInterface){
        return GenericNameServiceInterface(_accessControl);
    }

    function manager() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_Manager);
    }

    function miner() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_Miner);
    }

    function deputyCenter() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_DeputyCenter);
    }

    function vrfCenter() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_VRFCenter);
    }

    function vrfSigner() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_VRFSigner);
    }

    function assetVault() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_AssetVault);
    }

    function safetyCluster() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_SafetyCluster);
    }

    function safetyPlanetLogic() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_SafetyPlanetLogic);
    }

    function safetyBoxLogic() view internal returns (address){
        return ns().getSingleSafe(GenericNameServiceType.S_SafetyBoxLogic);
    }

    function isServer(address input) view internal returns (bool){
        return ns().isMultiple(GenericNameServiceType.M_Server, input);
    }

    function isTrusted(address input) view internal returns (bool){
        return ns().isTrusted(input);
    }

    function _setNameService(address ns_) internal {
        _setAccessControl(ns_);
    }
}
