// SPDX-License-Identifier: MIT
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../safetyBox/GenericSafetyBoxInterface.sol';

pragma solidity ^0.8.0;

library FundLibrary {

    using SafeERC20 for IERC20;

    //from
    //SB
    //safetyBox
    //self

    //to
    //SB+safetyBox
    //self

    //3*2 -1(self to self)=6

    //some body => some address / safety box address
    function _fundFromSBToSBOrSafetyBox(address token, address from, address to, uint256 amount) internal {
        require(from != address(this), "_fundFromSBToSBOrSafetyBox, can not send fund from self");
        require(to != address(this), "_fundFromSBToSBOrSafetyBox, can not take fund to self");
        require(from != to, "_fundFromSBToSBOrSafetyBox, can not move fund from and to same one");

        if (token != address(0)) {
            require(amount <= IERC20(token).balanceOf(from), "_fundFromSBToSBOrSafetyBox, from address insufficient erc20 token");
            require(amount <= IERC20(token).allowance(from, address(this)), "_fundFromSBToSBOrSafetyBox, from address insufficient allownance");
            IERC20(token).safeTransferFrom(from, to, amount);
        } else {
            require(msg.sender == from, "_fundFromSBToSBOrSafetyBox, you can't take native token from one who is not the msg.sender");
            require(amount <= msg.value, "_fundFromSBToSBOrSafetyBox, native token not enough");
            Address.sendValue(payable(to), amount);
        }
    }

    //some body => this contract address
    function _fundFromSBToSelf(address token, address from, uint256 amount) internal {
        require(from != address(this), "_fundFromSBToSelf, can not send fund from self");

        if (token != address(0)) {
            require(amount <= IERC20(token).balanceOf(from), "_fundFromSBToSelf, from address insufficient erc20 token");
            require(amount <= IERC20(token).allowance(from, address(this)), "_fundFromSBToSelf, from address insufficient allowance");
            IERC20(token).safeTransferFrom(from, address(this), amount);
        } else {
            require(msg.sender == from, "_fundFromSBToSelf, you can't take native token from one who is not the msg.sender");
            require(amount <= msg.value, "_fundFromSBToSelf, native token enough");
        }
    }


    function _fundFromSafetyBoxToSBOrSafetyBox(address token, address fromSafetyBox, address to, uint256 amount) internal {
        require(to != address(this), "_fundFromSafetyBoxToSBOrSafetyBox, can not take fund to self");

        GenericSafetyBoxInterface(fromSafetyBox).takeErc20(token, to, amount);
    }

    function _fundFromSafetyBoxToSelf(address token, address fromSafetyBox, uint256 amount) internal {
        GenericSafetyBoxInterface(fromSafetyBox).takeErc20(token, address(this), amount);
    }

    //self => some address / safety box address
    function _fundFromSelfToSBOrSafetyBox(address token, address to, uint256 amount) internal {
        require(to != address(this), "_fundFromSelfToSBOrSafetyBox, can not take fund to self");

        if (token != address(0)) {
            require(amount <= IERC20(token).balanceOf(address(this)), "_fundFromSelfToSBOrSafetyBox, self insufficient erc20 token");
            IERC20(token).safeTransfer(to, amount);
        } else {
            require(amount <= address(this).balance, "_fundFromSelfToSBOrSafetyBox, self native token not enough");
            Address.sendValue(payable(to), amount);
        }
    }
}
