// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "./ChainlinkClientEvent.sol";

import "./ChainlinkClientType.sol";

interface ChainlinkClientInterface is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
ChainlinkClientEvent {

}
