// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameServiceLayout.sol";
import "../dependant/nameService/GenericNameServiceLogic.sol";
import "./NameServiceInterface.sol";

contract NameServiceLogic is Delegate, NameServiceLayout, GenericNameServiceLogic, NameServiceInterface {

}
