// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../erc165/HERC165Interface.sol";
import "../context/ContextInterface.sol";
import "./HERC721Event.sol";

import "@openzeppelin/contracts/interfaces/IERC4906.sol";

interface HERC721Interface is HERC165Interface, ContextInterface, IERC721, IERC721Metadata, IERC4906, IERC721Enumerable, HERC721Event {
}
