// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface HERC721IMEvent {

    event SetAccessControl(address accessControl);

    event SetSupport(bool supportTransfer, bool supportMint, bool supportBurn);

    event Mint(address indexed to, uint256 indexed tokenId);

    event Burn(address indexed from, uint256 indexed tokenId);

    event Freeze(address indexed unlocker, uint256 indexed tokenId);

    event Thaw(address indexed unlocker, uint256 indexed tokenId);

    event allAttribute(
        bytes32[] attributeNames,
        uint256 tokenId,
        address changeRequester,
        uint256[] uint256AttributeValues,
        bytes32[] bytes32AttributeValues,
        address[] addressAttributeValues,
        bytes[] bytesAttributeValues
    );
}
