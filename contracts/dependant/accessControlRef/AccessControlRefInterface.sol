// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "./AccessControlRefEvent.sol";

interface AccessControlRefInterface is AccessControlRefEvent {

    function accessControl() view external returns (address);

}
