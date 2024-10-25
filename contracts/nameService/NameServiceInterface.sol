// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/nameService/GenericNameServiceInterface.sol";
import "./NameServiceEvent.sol";

interface NameServiceInterface is GenericNameServiceInterface, NameServiceEvent {

}
