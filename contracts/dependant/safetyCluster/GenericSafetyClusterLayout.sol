// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLayout.sol";

import "./GenericSafetyClusterType.sol";

contract GenericSafetyClusterLayout is OwnableLayout, GenericNameServiceRefLayout {

    mapping(uint256 => GenericSafetyClusterType.Config) internal _config;

    mapping(uint256 => GenericSafetyClusterType.Bill) internal _bill;

    EnumerableSet.AddressSet internal _interactedErc20Tokens;
    EnumerableSet.AddressSet internal _interactedErc721Tokens;
    EnumerableSet.AddressSet internal _interactedErc1155Tokens;

    EnumerableSet.Bytes32Set internal _interactedCategory;
    //all active=UNDEPLOYED+NORMAL planet indexs
    EnumerableSet.UintSet internal _activePlanetIndex;

    //planetIndex => planet details, starts from 1
    mapping(uint256 => GenericSafetyClusterType.PlanetInfo) internal _planetInfo;

    //================

    //category => token => balance
    mapping(bytes32 => mapping(address => uint256)) internal _categoryErc20Balance;

    //planetIndex => token => balance
    mapping(uint256 => mapping(address => uint256)) internal _planetErc20Balance;

    //================

    //category => token => nftId balance
    mapping(bytes32 => mapping(address => uint256)) internal _categoryErc721Balance;

    //planetIndex => token => nftIds
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal _planetErc721Balance;

    //token => nft id => planetIndex
    mapping(address => mapping(uint256 => uint256)) internal _planetErc721NftTracker;

    //================

    //category => token => id => balance
    mapping(bytes32 => mapping(address => mapping(uint256 => uint256))) internal _categoryErc1155Balance;

    //planetIndex => token => id => balance
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _planetErc1155Balance;
}
