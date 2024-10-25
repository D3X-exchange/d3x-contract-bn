// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableInterface.sol";
import "../nameServiceRef/GenericNameServiceRefInterface.sol";
import "./GenericDeputyCenterEvent.sol";

import "./GenericDeputyCenterType.sol";

interface GenericDeputyCenterInterface is OwnableInterface, GenericNameServiceRefInterface, GenericDeputyCenterEvent {

    function dispatchTransactions(GenericDeputyCenterType.BatchTransactions[] memory bTxs) external;

    function calledAndCaller() view external returns (bool called, address caller);
}
