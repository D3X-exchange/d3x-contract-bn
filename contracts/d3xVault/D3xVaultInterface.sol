// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "./D3xVaultEvent.sol";

import "./D3xVaultType.sol";
import "../dependant/erc4626/HERC4626Interface.sol";

interface D3xVaultInterface is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
HERC4626Interface,
D3xVaultEvent {
    function takeAsset(uint256 assetAmount, address who) external;

    function receiveAsset(uint256 assetAmount, address who) external;

    function receiveProfit(uint256 assetAmount, address who) external;

    function getAsset() external view returns(address);
}
