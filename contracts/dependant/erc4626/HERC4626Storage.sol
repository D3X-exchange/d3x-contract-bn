// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC4626Layout.sol";
import "../erc20improved/HERC20IMStorage.sol";

import "../erc20improved/HERC20IMInterface.sol";
import "../erc20improved/HERC20IMType.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
abstract contract HERC4626Storage is HERC4626Layout, HERC20IMStorage {

    constructor (
        address asset_,
        HERC20IMType.ConstructorParam memory param,
        address owner_
    )
    HERC20IMStorage(param, owner_){
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(IERC20(asset_));
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }
}
