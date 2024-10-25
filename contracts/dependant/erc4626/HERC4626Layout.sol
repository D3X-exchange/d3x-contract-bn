// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../erc20improved/HERC20IMLayout.sol";

abstract contract HERC4626Layout is HERC20IMLayout {

    address internal _asset;
    uint8 internal _underlyingDecimals;//asset's decimal

}
