// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../nameServiceRef/GenericNameServiceRefInterface.sol";
import "./DeputyRefEvent.sol";

interface DeputyRefInterface is GenericNameServiceRefInterface, DeputyRefEvent {

}
