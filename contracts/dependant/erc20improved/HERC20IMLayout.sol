// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLayout.sol";
import "../reentrancy/ReentrancyLayout.sol";
import "../erc20/HERC20Layout.sol";

//erc20, ownable, erc20im
abstract contract HERC20IMLayout is OwnableLayout, GenericNameServiceRefLayout, ReentrancyLayout, HERC20Layout {

    bool internal _supportTransfer;
    bool internal _supportMint;
    bool internal _sudoMint;
    bool internal _supportBurn;
    bool internal _sudoBurn;

    //statistic
    uint256 internal _transferTxs;
    uint256 internal _transferAmounts;

    EnumerableSet.AddressSet internal _interactAccounts;


    mapping(address => bool) internal _blockListFrom;
    mapping(address => bool) internal _blockListTo;
    mapping(address => bool) internal _privilegeListFrom;
    mapping(address => bool) internal _privilegeListTo;
}
