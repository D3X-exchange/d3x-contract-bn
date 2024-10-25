// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC20Layout.sol";
import "../context/ContextStorage.sol";
import "../eip712/HEIP712Storage.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
contract HERC20Storage is HERC20Layout, ContextStorage, HEIP712Storage {

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 cap_
    )
    ContextStorage()
    HEIP712Storage(name_, "1"){
        _name = name_;
        _symbol = symbol_;

        _decimals = 18;

        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }
}
