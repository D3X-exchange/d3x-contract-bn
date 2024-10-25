// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../erc165/HERC165Interface.sol";
import "../context/ContextInterface.sol";
import "./HERC1155Event.sol";

interface HERC1155Interface is HERC165Interface, ContextInterface, IERC1155, IERC1155MetadataURI, HERC1155Event {


    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Total value of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}
