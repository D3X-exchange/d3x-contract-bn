// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HEIP712Type {

    bytes32 internal constant TYPE_HASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

}
