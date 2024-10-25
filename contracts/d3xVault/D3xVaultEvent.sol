// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xVaultType.sol";

interface D3xVaultEvent {

    event TakeAsset(uint256 assetAmount,address who);
    event ReceiveAsset(uint256 assetAmount,address who);
    event ReceiveProfit(uint256 assetAmount,address who);
}
