// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ownable/OwnableLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLayout.sol";

import "./GenericSafetyBoxType.sol";

contract GenericSafetyBoxLayout is OwnableLayout, GenericNameServiceRefLayout {
}
