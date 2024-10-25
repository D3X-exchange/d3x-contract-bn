// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "./TWAPPriceGetterEvent.sol";

import "./TWAPPriceGetterType.sol";

interface TWAPPriceGetterInterface is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
TWAPPriceGetterEvent {

    function d3xPriceInX(address inCurrency) external view returns (uint256 price);

    function setPoolConfig(TWAPPriceGetterType.PoolConfig[] calldata addConfig, address[] calldata removeConfig) external;
}
