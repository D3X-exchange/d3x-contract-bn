// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ownable/OwnableInterface.sol";
import "../nameServiceRef/GenericNameServiceRefInterface.sol";
import "./GenericSafetyBoxEvent.sol";

import "./GenericSafetyBoxType.sol";

interface GenericSafetyBoxInterface is OwnableInterface, GenericNameServiceRefInterface, GenericSafetyBoxEvent {

    function takeErc20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external;

    function takeErc20s(
        address[] calldata tokenAddresses,
        address[] calldata tos,
        uint256[] calldata amounts
    ) external;

    function takeErc721(
        address tokenAddress,
        address to,
        uint256 amount
    ) external;

    function takeErc721s(
        address[] calldata nftAddresses,
        address[] calldata tos,
        uint256[] calldata nftIds
    ) external;

    function takeErc1155(
        address tokenAddress,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function takeErc1155s(
        address[] calldata tokenAddresses,
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}
