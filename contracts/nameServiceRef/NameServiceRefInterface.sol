// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/nameServiceRef/GenericNameServiceRefInterface.sol";
import "./NameServiceRefEvent.sol";

interface NameServiceRefInterface is GenericNameServiceRefInterface, NameServiceRefEvent {
}
