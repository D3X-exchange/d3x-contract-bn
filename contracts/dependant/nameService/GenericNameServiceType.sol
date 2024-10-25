// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GenericNameServiceType {

    //copy the following declaration into new contract cause the compiler is not so smart for constant reference
    bytes32 constant SINGLE_REGISTRY_UNKNOWN = "";
    bytes32 constant S_Miner = "Miner";
    bytes32 constant S_Manager = "Manager";
    bytes32 constant S_DeputyCenter = "DeputyCenter";
    bytes32 constant S_VRFCenter = "VRFCenter";
    bytes32 constant S_VRFSigner = "VRFSigner";
    bytes32 constant S_AssetVault = "AssetVault";
    bytes32 constant S_SafetyCluster = "SafetyCluster";


    bytes32 constant S_SafetyPlanetLogic = "SafetyPlanetLogic";
    bytes32 constant S_SafetyBoxLogic = "SafetyBoxLogic";

    bytes32 constant MULTIPLE_REGISTRY_UNKNOWN = "";
    bytes32 constant M_Server = "Server";

    struct AddressRecord {
        address addr;
        bool trusted;
    }

    struct SingleEntryParam {
        bytes32 name;
        AddressRecord record;
        bool enable;
    }

    struct SingleEntryRet {
        bytes32 name;
        AddressRecord record;
    }

    struct MultiEntryParam {
        bytes32 name;
        AddressRecord[] records;
        bool enable;
    }

    struct MultipleEntryRet {
        bytes32 name;
        AddressRecord[] records;
    }

}
