// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/safetyBox/GenericSafetyBoxLayout.sol";
import "../dependant/ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";

import "./SafetyBoxType.sol";

contract SafetyBoxLayout is GenericSafetyBoxLayout, NameServiceRefLayout {

}
