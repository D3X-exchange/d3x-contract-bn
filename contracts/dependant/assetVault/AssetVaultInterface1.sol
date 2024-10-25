// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../nameServiceRef/GenericNameServiceRefInterface.sol";

import "./AssetVaultEvent.sol";

interface AssetVaultInterface1 is GenericNameServiceRefInterface, AssetVaultEvent {

    function depositErc20(
        bytes32 erc20TokenName,
        address owner,
        uint256 amount
    ) external;

    function depositErc20s(
        bytes32[] memory erc20TokenNames,
        address owner,
        uint256[] memory amounts
    ) external;

    function withdrawErc20(
        bytes32 erc20TokenName,
        address owner,
        uint256 amount,
        uint256 traceId
    ) external;

    function withdrawErc20s(
        bytes32[] memory erc20TokenNames,
        address owner,
        uint256[] memory amounts,
        uint256 traceId
    ) external;

}
