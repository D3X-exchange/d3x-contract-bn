// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ownable/OwnableInterface.sol";
import "../nameServiceRef/GenericNameServiceRefInterface.sol";
import "./GenericSafetyPlanetEvent.sol";

import "./GenericSafetyPlanetType.sol";

interface GenericSafetyPlanetInterface is OwnableInterface, GenericNameServiceRefInterface, GenericSafetyPlanetEvent {

    function takeErc20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external;

    function takeErc721(
        address tokenAddress,
        address to,
        uint256 amount
    ) external;

    function takeErc1155(
        address tokenAddress,
        address to,
        uint256 id,
        uint256 amount
    ) external;
}
