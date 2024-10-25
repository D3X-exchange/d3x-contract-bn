// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "./HERC4626Event.sol";

interface HERC4626Interface is IERC4626, HERC4626Event {

}
