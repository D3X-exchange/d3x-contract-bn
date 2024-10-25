// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyClusterRefLayout.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "./GenericSafetyClusterRefInterface.sol";

import "../safetyCluster/GenericSafetyClusterInterface.sol";
import "../safetyBox/GenericSafetyBoxInterface.sol";

contract GenericSafetyClusterRefLogic is GenericSafetyClusterRefLayout, GenericNameServiceRefLogic, GenericSafetyClusterRefInterface {

    using SafeERC20 for IERC20;

    //some body => cluster
    function _takeFundToCluster(bytes32 category, address token, address from, address toClusterAddress, uint256 amount) internal {

        if (toClusterAddress == address(0)) {
            toClusterAddress = safetyPlanetLogic();
        }

        if (token != address(0)) {
            //first take token into this address
            IERC20(token).safeTransferFrom(from, address(this), amount);

            //check allowance
            if (IERC20(token).allowance(address(this), toClusterAddress) <= amount) {
                IERC20(token).approve(toClusterAddress, type(uint256).max);
            }

            //erc20: this contract => planet
            GenericSafetyClusterInterface(toClusterAddress).giveErc20(category, token, from, amount);

        } else {
            require(msg.sender == from, "_takeFundToCluster, you can't take native token from one who is not the msg.sender");
            require(msg.value >= amount, "_takeFundToCluster, native token enough");

            //native: this contract => cluster, cluster => planet
            GenericSafetyClusterInterface(toClusterAddress).giveErc20{value: amount}(category, token, from, amount);
        }
    }

    //==================================


    function _sendFundFromCluster(bytes32 category, address token, address fromClusterAddress, address to, uint256 amount) internal {
        if (fromClusterAddress == address(0)) {
            fromClusterAddress = safetyPlanetLogic();
        }

        //planet => some body
        GenericSafetyClusterInterface(fromClusterAddress).takeErc20(category, token, to, amount);
    }

    function _moveFundInCluster(bytes32 fromCategory, bytes32 toCategory, address token, address clusterAddress, uint256 amount) internal {
        if (clusterAddress == address(0)) {
            clusterAddress = safetyPlanetLogic();
        }

        GenericSafetyClusterInterface(clusterAddress).moveErc20(fromCategory, toCategory, token, address(this), address(this), amount);
    }
}
