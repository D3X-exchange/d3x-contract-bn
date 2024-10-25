// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyBoxLayout.sol";
import "../ownable/OwnableLogic.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "../holders/HERC1155HolderLogic.sol";
import "../holders/HERC721HolderLogic.sol";
import "./GenericSafetyBoxInterface.sol";

// asset vault
abstract contract GenericSafetyBoxLogic is GenericSafetyBoxLayout, OwnableLogic, GenericNameServiceRefLogic, HERC1155HolderLogic, HERC721HolderLogic, GenericSafetyBoxInterface {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    function _onlyAuthTrusted() virtual internal override view returns (bool){
        return isAuth() || ns().isTrusted(msg.sender);
    }

    /*
    only has 'take' function to transfer fund out of this address to some where
    */

    function takeErc20(
        address tokenAddress,
        address to,
        uint256 amount
    ) override external onlyAuthTrusted {
        if (tokenAddress != address(0)) {
            require(amount <= IERC20(tokenAddress).balanceOf(address(this)), "takeErc20, box insufficient erc20 token");
            IERC20(tokenAddress).safeTransfer(to, amount);
        } else {
            require(amount <= address(this).balance, "takeErc20: box insufficient native balance");
            Address.sendValue(payable(to), amount);
        }
    }

    function takeErc20s(
        address[] calldata tokenAddresses,
        address[] calldata tos,
        uint256[] calldata amounts
    ) override external onlyAuthTrusted {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            address to = tos[i];
            uint256 amount = amounts[i];
            if (tokenAddress != address(0)) {
                require(amount <= IERC20(tokenAddress).balanceOf(address(this)), "takeErc20, box insufficient erc20 token");
                IERC20(tokenAddress).safeTransfer(to, amount);
            } else {
                require(amount <= address(this).balance, "takeErc20: box insufficient native balance");
                Address.sendValue(payable(to), amount);
            }
        }
    }

    function takeErc721(
        address nftAddress,
        address to,
        uint256 nftId
    ) override external onlyAuthTrusted {
        IERC721(nftAddress).safeTransferFrom(address(this), to, nftId);
    }

    function takeErc721s(
        address[] calldata nftAddresses,
        address[] calldata tos,
        uint256[] calldata nftIds
    ) override external onlyAuthTrusted {
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(address(this), tos[i], nftIds[i]);
        }
    }

    function takeErc1155(
        address tokenAddress,
        address to,
        uint256 id,
        uint256 amount
    ) override external onlyAuthTrusted {
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, id, amount, "");
    }


    function takeErc1155s(
        address[] calldata tokenAddresses,
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) override external onlyAuthTrusted {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {

            address tokenAddress = tokenAddresses[i];
            address to = tos[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            IERC1155(tokenAddress).safeTransferFrom(address(this), to, id, amount, "");
        }
    }
}
