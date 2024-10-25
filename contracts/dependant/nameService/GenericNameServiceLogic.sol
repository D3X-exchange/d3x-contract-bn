// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericNameServiceLayout.sol";
import "../accessControl/AccessControlLogic.sol";
import "./GenericNameServiceInterface.sol";

contract GenericNameServiceLogic is GenericNameServiceLayout, AccessControlLogic, GenericNameServiceInterface {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function isMultiple(bytes32 name, address which) override view external returns (bool){
        return _multipleKeyAddress[name].contains(which);
    }

    function isMultipleSafe(bytes32 name, address which) override view external returns (bool){
        if (!_multipleKeys.contains(name)) {
            revert(string(abi.encodePacked("isMultipleSafe, keyName not set: ", name)));
        }
        return _multipleKeyAddress[name].contains(which);
    }

    function getSingle(bytes32 name) override view external returns (address){
        return _singleRegistry[name].addr;
    }

    function getSingleSafe(bytes32 name) override view external returns (address){
        if (!_singleKeys.contains(name)) {
            revert(string(abi.encodePacked("getSingleSafe, keyName not set: ", name)));
        }
        return _singleRegistry[name].addr;
    }

    function getEnv(bytes32 envName) override view external returns (uint256){
        return _envRegistry[envName];
    }

    function getEnvSafe(bytes32 envName) override view external returns (uint256){
        if (!_envKeys.contains(envName)) {
            revert(string(abi.encodePacked("getEnvSafe, envName not set: ", envName)));
        }
        return _envRegistry[envName];
    }

    function isTrusted(address which) override view external returns (bool){

        for (uint256 i = 0; i < _singleKeys.length(); i++) {
            bytes32 name = _singleKeys.at(i);


            if (_singleRegistry[name].addr == which) {
                //find

                if (_singleRegistry[name].trusted) {
                    return true;
                }

            }
        }

        for (uint256 i = 0; i < _multipleKeys.length(); i++) {
            bytes32 name = _multipleKeys.at(i);

            for (uint256 j = 0; j < _multipleKeyAddress[name].length(); j++) {
                address addr = _multipleKeyAddress[name].at(j);

                if (addr == which) {
                    if (_multipleRegistry[name][addr].trusted) {
                        return true;
                    }
                }
                //continue find
            }
        }

        return false;
    }
    //==========

    function setEntries(
        GenericNameServiceType.SingleEntryParam[] calldata singleParams,
        GenericNameServiceType.MultiEntryParam[] calldata multiParams
    ) override external onlyOwner {

        for (uint256 i = 0; i < singleParams.length; i++) {
            GenericNameServiceType.SingleEntryParam calldata singleParam = singleParams[i];

            if (singleParam.enable) {
                //maybe already set, just modify
                if (!_singleKeys.contains(singleParam.name)) {
                    _singleKeys.add(singleParam.name);
                }
                //address maybe 0
                _singleRegistry[singleParam.name] = singleParam.record;

            } else {
                require(singleParam.record.addr == address(0), "setSingleEntries must be 0 while disable the key");
                require(!singleParam.record.trusted, "setSingleEntries, trusted must be false while remove key");

                _singleKeys.remove(singleParam.name);
                delete _singleRegistry[singleParam.name];
            }
        }

        for (uint256 i = 0; i < multiParams.length; i++) {
            GenericNameServiceType.MultiEntryParam calldata multiParam = multiParams[i];

            bytes32 key = multiParam.name;
            bool enable = multiParam.enable;

            for (uint256 j = 0; j < multiParam.records.length; j++) {
                GenericNameServiceType.AddressRecord calldata addressRecord = multiParam.records[j];

                address addr = addressRecord.addr;
                bool trusted = addressRecord.trusted;

                if (enable) {
                    //0 -> 1
                    if (_multipleKeyAddress[key].length() == 0) {
                        _multipleKeys.add(key);
                    }
                    _multipleKeyAddress[key].add(addr);
                    _multipleRegistry[key][addr] = addressRecord;

                } else {

                    require(addr == address(0), "setMultipleEntries must be 0 while disable the key");
                    require(!trusted, "setMultipleEntries, trusted must be false while remove key");

                    delete _multipleRegistry[key][addr];
                    _multipleKeyAddress[key].remove(addr);

                    //1 -> 0
                    if (_multipleKeyAddress[key].length() == 0) {
                        _multipleKeys.remove(key);
                    }
                }
            }
        }
    }

    function listEntries() override view external returns (
        GenericNameServiceType.SingleEntryRet[] memory singleEntries,
        GenericNameServiceType.MultipleEntryRet[] memory multipleEntries
    ){

        singleEntries = new GenericNameServiceType.SingleEntryRet[](_singleKeys.length());

        for (uint256 i = 0; i < _singleKeys.length(); i++) {
            bytes32 key = _singleKeys.at(i);
            singleEntries[i].name = key;
            singleEntries[i].record = _singleRegistry[key];
        }

        multipleEntries = new GenericNameServiceType.MultipleEntryRet[](_multipleKeys.length());

        for (uint256 i = 0; i < _multipleKeys.length(); i++) {
            bytes32 name = _multipleKeys.at(i);
            multipleEntries[i].name = name;

            multipleEntries[i].records = new GenericNameServiceType.AddressRecord[](_multipleKeyAddress[name].length());

            for (uint256 j = 0; j < _multipleKeyAddress[name].length(); j++) {
                address addr = _multipleKeyAddress[name].at(j);
                multipleEntries[i].records[j] = _multipleRegistry[name][addr];
            }
        }

        return (singleEntries, multipleEntries);
    }
}
