// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ChainlinkClientType {

    uint256 internal constant LINK_DIVISIBILITY = 10 ** 18;
    uint256 internal constant AMOUNT_OVERRIDE = 0;
    address internal constant SENDER_OVERRIDE = address(0);
    uint256 internal constant ORACLE_ARGS_VERSION = 1;
    uint256 internal constant OPERATOR_ARGS_VERSION = 2;
    bytes32 internal constant ENS_TOKEN_SUBNAME = keccak256("link");
    bytes32 internal constant ENS_ORACLE_SUBNAME = keccak256("oracle");
    address internal constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

}
