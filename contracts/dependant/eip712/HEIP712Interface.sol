// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../context/ContextInterface.sol";
import "@openzeppelin/contracts/interfaces/IERC5267.sol";
import "./HEIP712Event.sol";

interface HEIP712Interface is ContextInterface, IERC5267, HEIP712Event {

    /**
    * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);
}
