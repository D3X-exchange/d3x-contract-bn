// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC1155Layout.sol";
import "../erc165/HERC165Storage.sol";
import "../context/ContextStorage.sol";

import "./HERC1155Interface.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
contract HERC1155Storage is HERC1155Layout, HERC165Storage, ContextStorage {

    constructor (
        string memory uri_
    )
    HERC165Storage()
    ContextStorage()
    {
        _uri = uri_;

        _registerInterface(type(IERC1155).interfaceId);
        _registerInterface(type(IERC1155MetadataURI).interfaceId);

    }
}
