// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "./D3xTemplateEvent.sol";

import "./D3xTemplateType.sol";

interface D3xTemplateInterface is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
D3xTemplateEvent {

}
