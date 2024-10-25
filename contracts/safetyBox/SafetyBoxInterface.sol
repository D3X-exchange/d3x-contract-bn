// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/safetyBox/GenericSafetyBoxInterface.sol";
import "../nameServiceRef/NameServiceRefInterface.sol";
import "./SafetyBoxEvent.sol";

import "./SafetyBoxType.sol";

interface SafetyBoxInterface is GenericSafetyBoxInterface, NameServiceRefInterface, SafetyBoxEvent {
}
