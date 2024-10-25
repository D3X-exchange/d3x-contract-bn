// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyLayout.sol";
import "./ReentrancyInterface.sol";

contract ReentrancyLogic is ReentrancyLayout, ReentrancyInterface {

    modifier onlySelf(){

        require(!_reentrancyOnceMark, "Reentrancy: onlyOnce");

        require(msg.sender == address(this), "Reentrancy: onlySelf");

        _reentrancyOnlySelfCount += 1;

        _;

        _reentrancyOnlySelfCount -= 1;
    }

    //onlySelf -> onlyOnce is supported
    modifier onlyOnce(){

        require(!_reentrancyOnceMark, "Reentrancy: onlyOnce");

        _reentrancyOnceMark = true;

        _;

        _reentrancyOnceMark = false;
    }

}
