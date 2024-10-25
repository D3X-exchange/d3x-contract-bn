// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../context/ContextLayout.sol";
import "../eip712/HEIP712Layout.sol";

abstract contract HERC20Layout is ContextLayout, HEIP712Layout {

    mapping(address account => uint256) internal _balances;

    mapping(address account => mapping(address spender => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint256 internal _cap;

}
