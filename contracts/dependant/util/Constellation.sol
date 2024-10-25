// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Constellation is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    constructor()
    Ownable(msg.sender){

    }


    function distribute(
        IERC20 token,
        address from,
        address payable[] calldata to,
        uint256[] calldata amounts,
        uint256 amount,
        bool noError
    ) payable external {

        require(0 < to.length, "to.length is 0");

        if (address(token) == address(0)) {
            require(from == msg.sender, "distributing native token only supports from = msg.sender");
            if (noError) {

                if (0 < amounts.length) {
                    for (uint256 i = 0; i < to.length; i++) {
                        to[i].sendValue(amounts[i]);
                    }
                } else {
                    for (uint256 i = 0; i < to.length; i++) {
                        to[i].sendValue(amount);
                    }
                }

            } else {

                if (0 < amounts.length) {
                    for (uint256 i = 0; i < to.length; i++) {
                        (bool r,bytes memory ret) = payable(to[i]).call{value: amounts[i]}("");
                        r;
                        ret;
                    }
                } else {
                    for (uint256 i = 0; i < to.length; i++) {
                        (bool r,bytes memory ret) = payable(to[i]).call{value: amount}("");
                        r;
                        ret;
                    }
                }

            }
        } else {
            //erc20
            require(msg.sender == from || msg.sender == owner(), "distributing erc20 only supports msg.sender == from or || msg.sender == owner()");

            if (noError) {

                if (0 < amounts.length) {

                    for (uint256 i = 0; i < to.length; i++) {
                        token.safeTransferFrom(from, to[i], amounts[i]);
                    }

                } else {

                    for (uint256 i = 0; i < to.length; i++) {
                        token.safeTransferFrom(from, to[i], amount);
                    }

                }

            } else {

                if (0 < amounts.length) {

                    for (uint256 i = 0; i < to.length; i++) {
                        try token.transferFrom(from, to[i], amounts[i]){}
                        //                    catch Error(string memory /*reason*/){
                        //                        //ignore
                        //                    }
                        catch (bytes memory /*lowLevelData*/) {
                            //ignore
                        }
                    }

                } else {

                    for (uint256 i = 0; i < to.length; i++) {
                        try token.transferFrom(from, to[i], amount){}
                        //                    catch Error(string memory /*reason*/){
                        //                        //ignore
                        //                    }
                        catch (bytes memory /*lowLevelData*/) {
                            //ignore
                        }
                    }

                }

            }
        }
    }

    function collect(
        IERC20 token,
        address payable[] calldata from,
        uint256[] calldata amounts,
        address to
    ) payable external onlyOwner {

        if (to == address(0)) {
            to = msg.sender;
        }

        if (address(token) == address(0)) {
            revert("collect error!!");
        }

        if (from.length == amounts.length) {
            for (uint256 i = 0; i < from.length; i++) {
                token.safeTransferFrom(from[i], to, amounts[i]);
            }
        } else if (amounts.length == 0) {
            for (uint256 i = 0; i < from.length; i++) {
                uint256 balance = token.balanceOf(from[i]);
                token.safeTransferFrom(from[i], to, balance);
            }
        } else {
            revert("amounts.length");
        }

    }

    function collectAllAndToAndTop(
        IERC20 token,
        address payable[] calldata from,
        address to,
        uint256 cover
    ) payable external onlyOwner {
        if (address(token) == address(0)) {
            revert("error!!");
        }

        uint256 balance = token.balanceOf(to);

        for (uint256 i = 0; i < from.length; i++) {

            uint256 has = token.balanceOf(from[i]);

            if (has == 0) {
                continue;
            }

            uint256 need = 0;
            if (balance + has > cover) {
                need = cover - balance;
                //surplus
            } else {
                need = has;
            }

            token.safeTransferFrom(from[i], to, need);

            balance = balance + need;
            if (balance >= cover) {
                return;
            }
        }

    }

    function Erc20BalancesOfTogether(IERC20 token, address[] calldata from) view external returns (uint256 total, uint256[]memory balances){
        total = 0;
        balances = new uint256[](from.length);
        if (address(token) == address(0)) {
            for (uint256 i = 0; i < from.length; i++) {
                uint256 b = from[i].balance;
                balances[i] = b;
                total += b;
            }
        } else {
            for (uint256 i = 0; i < from.length; i++) {
                uint256 b = token.balanceOf(from[i]);
                balances[i] = b;
                total += b;
            }
        }
        return (total, balances);
    }

    function Erc721BalanceOfTogether(IERC721 token, address[] calldata from) view external returns (uint256 total, uint256[]memory balances){
        total = 0;
        balances = new uint256[](from.length);
        for (uint256 i = 0; i < from.length; i++) {
            uint256 b = token.balanceOf(from[i]);
            balances[i] = b;
            total += token.balanceOf(from[i]);
        }
        return (total, balances);
    }

    function meta() view external returns (uint256 blockHeight, uint256 blockTimestamp){
        return (block.number, block.timestamp);
    }

}
