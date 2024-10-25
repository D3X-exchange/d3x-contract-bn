// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract TestUsdt is ERC20Capped {

    constructor()
    ERC20Capped(1_000_000_000 * 10 ** 18) ERC20("TestUsdt", "TestUsdt"){
        _mint(msg.sender,1_000_000_000 * 10 ** 18);
    }

}
