// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../accessControl/AccessControlInterface.sol";
import "./GenericNameServiceEvent.sol";

import "./GenericNameServiceType.sol";

interface GenericNameServiceInterface is AccessControlInterface, GenericNameServiceEvent {

    function isMultiple(bytes32 keyName, address which) view external returns (bool);

    function isMultipleSafe(bytes32 keyName, address which) view external returns (bool);

    function getSingle(bytes32 keyName) view external returns (address);

    function getSingleSafe(bytes32 keyName) view external returns (address);

    function getEnv(bytes32 envName) view external returns (uint256);

    function getEnvSafe(bytes32 envName) view external returns (uint256);

    function isTrusted(address addr) view external returns (bool);
    //==========

    function setEntries(
        GenericNameServiceType.SingleEntryParam[] calldata singleParams,
        GenericNameServiceType.MultiEntryParam[] calldata multiParams
    ) external;

    function listEntries() view external returns (
        GenericNameServiceType.SingleEntryRet[] memory singleEntries,
        GenericNameServiceType.MultipleEntryRet[] memory multipleEntries
    );
}
