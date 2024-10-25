// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";
import "../dependant/erc4626/HERC4626Layout.sol";

import "./D3xVaultType.sol";

contract D3xVaultLayout is
OwnableLayout,
NameServiceRefLayout,
HERC4626Layout {

    uint256 internal _cumulativeProfit;

    uint256 internal _cumulativeGivenAsset;
    uint256 internal _cumulativeTakenAsset;
}


