// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ownable/OwnableInterface.sol";
import "../nameServiceRef/GenericNameServiceRefInterface.sol";
import "./GenericSafetyClusterEvent.sol";

import "./GenericSafetyClusterType.sol";

interface GenericSafetyClusterInterface is OwnableInterface, GenericNameServiceRefInterface, GenericSafetyClusterEvent {

    function giveErc20(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256 amount
    ) external payable;

    function takeErc20(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256 amount
    ) external;

    function moveErc20(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256 amount
    ) external;

    function giveErc721(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256 nftId
    ) external;

    //avoid overload for js/ts indexed field to get function
    function giveErc721s(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256[] calldata nftIds
    ) external;

    function takeErc721(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256 nftId
    ) external;

    function takeErc721s(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256[] calldata nftIds
    ) external;

    function moveErc721(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256 nftId
    ) external;

    function moveErc721s(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256[] calldata nftIds
    ) external;

    function giveErc1155(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256 id,
        uint256 amount
    ) external;

    function takeErc1155(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function moveErc1155(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256 id,
        uint256 amount
    ) external;

    function birth(uint256 planetCount) external;

    function nova() external;

    function getConfig() external view returns (GenericSafetyClusterType.Config memory);

    function getBill(uint256 start, uint256 maxNumber) external view returns (GenericSafetyClusterType.Bill[] memory ret, bool hasMore);

    function getInteractedTokens() external view returns (address[] memory erc20tokens, address[] memory erc721tokens, address[] memory erc1155tokens);

    function getInteractedCategory() external view returns (bytes32[] memory);

    //call this static
    function getErc20Balance(bytes32 category, address tokenAddress) external returns (
        uint256 categoryBalance,
        uint256 planetReportBalance,
        uint256 planetActualBalance
    );
}
