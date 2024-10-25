// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyPlanetLayout.sol";
import "../ownable/OwnableLogic.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "../holders/HERC1155HolderLogic.sol";
import "../holders/HERC721HolderLogic.sol";
import "./GenericSafetyPlanetInterface.sol";

// asset vault
abstract contract GenericSafetyPlanetLogic is GenericSafetyPlanetLayout, OwnableLogic, GenericNameServiceRefLogic, HERC1155HolderLogic, HERC721HolderLogic, GenericSafetyPlanetInterface {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyAuthPermitted{
        require(_onlyAuthPermitted(), "onlyAuthPermitted");
        _;
    }

    function _onlyAuthPermitted() virtual internal returns (bool){
        return owner() == msg.sender ||
        _associatedOperators[msg.sender] ||
        safetyCluster() == msg.sender ||
            manager() == msg.sender;
    }

    function takeErc20(
        address tokenAddress,
        address to,
        uint256 amount
    ) override external onlyAuthPermitted {
        if (tokenAddress != address(0)) {
            require(amount <= IERC20(tokenAddress).balanceOf(address(this)), "takeErc20, planet insufficient erc20 token");
            IERC20(tokenAddress).safeTransfer(to, amount);
        } else {
            require(amount <= address(this).balance, "takeErc20: planet insufficient native balance");
            Address.sendValue(payable(to), amount);
        }
    }

    function takeErc721(
        address tokenAddress,
        address to,
        uint256 amount
    ) override external onlyAuthPermitted {
        IERC721(tokenAddress).safeTransferFrom(address(this), to, amount);
    }

    function takeErc1155(
        address tokenAddress,
        address to,
        uint256 id,
        uint256 amount
    ) override external onlyAuthPermitted {
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, id, amount, "");

    }
}
