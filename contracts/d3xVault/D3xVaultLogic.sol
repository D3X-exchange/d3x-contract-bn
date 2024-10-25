// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xVaultLayout.sol";
import "../dependant/ownable/OwnableLogic.sol";
import "../nameServiceRef/NameServiceRefLogic.sol";
import "../dependant/erc4626/HERC4626Logic.sol";
import "./D3xVaultInterface.sol";

import "./D3xVaultType.sol";
import 'contracts/dependant/helperLibrary/FundLibrary.sol';

contract D3xVaultLogic is Delegate, D3xVaultLayout,
OwnableLogic,
NameServiceRefLogic,
HERC4626Logic,
D3xVaultInterface
{
    using SafeERC20 for IERC20;
    using Math for uint;

    function takeAsset(uint256 assetAmount, address who) external {

        address managerAddress = manager();
        address sender = _msgSender();
        require(sender == managerAddress, "only manager");

        if (_asset != address(0)) {
            require(assetAmount <= IERC20(_asset).balanceOf(address(this)), "takeErc20, box insufficient erc20 token");
            IERC20(_asset).safeTransfer(sender, assetAmount);
        } else {
            require(assetAmount <= address(this).balance, "takeErc20: box insufficient native balance");
            Address.sendValue(payable(sender), assetAmount);
        }

        _cumulativeTakenAsset += assetAmount;

        emit TakeAsset(assetAmount, who);
    }

    function receiveAsset(uint256 assetAmount, address who) external {

        address managerAddress = manager();
        address sender = _msgSender();
        require(sender == managerAddress, "only manager");

        FundLibrary._fundFromSBToSelf(_asset, managerAddress, assetAmount);

        _cumulativeGivenAsset += assetAmount;

        emit ReceiveAsset(assetAmount, who);
    }

    function receiveProfit(uint256 assetAmount, address who) external {

        address managerAddress = manager();
        address sender = _msgSender();
        require(sender == managerAddress, "only manager");

        FundLibrary._fundFromSBToSelf(_asset, managerAddress, assetAmount);

        _cumulativeProfit += assetAmount;

        emit ReceiveProfit(assetAmount, who);
    }

    function getAsset() external view returns(address){
        return _asset;
    }
}
