// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HERC1155IMType {

    struct ConstructorParam {
        string uri;
        bool supportTransfer;
        bool supportMint;
        bool supportBurn;
    }
}
