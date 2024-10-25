// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlotData.sol";
import "../nameService/GenericNameServiceInterface.sol";
import "../helperLibrary/ConstantLibrary.sol";

//!!!!do not use any memory while using _delegate()!!!!!
//this proxy is to get delegator address from name service and provided name service key
contract NameServiceProxy {

    using SlotData for bytes32;

    //admin
    bytes32 constant internal adminSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("adminSlot"))))));

    bytes32 constant revertMessageSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("revertMessageSlot"))))));

    bytes32 constant outOfServiceSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("outOfServiceSlot"))))));

    //name service address
    bytes32 constant internal nameServiceAddressSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("nameServiceAddressSlot"))))));

    //the bytes32 key name of name service
    bytes32 constant internal nameServiceKeySlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("nameServiceKeySlot"))))));

    bytes32 constant transparentSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("transparentSlot"))))));

    constructor (
        address nameServiceAddress,
        bytes32 nameServiceKey,
        address admin
    ) {
        require(admin != address(0));

        adminSlot.sysSaveSlotDataAddress(admin);
        nameServiceAddressSlot.sysSaveSlotDataAddress(nameServiceAddress);
        nameServiceKeySlot.sysSaveSlotData(nameServiceKey);
        transparentSlot.sysSaveSlotDataUint256(1);
    }

    //=============================================

    function sysGetAdmin() view public returns (address){
        return adminSlot.sysLoadSlotDataAddress();
    }

    function sysSetAdmin(address _input) external onlyAdmin {
        adminSlot.sysSaveSlotDataAddress(_input);
    }

    function sysGetRevertMessage() view public returns (uint256){
        return revertMessageSlot.sysLoadSlotDataUint256();
    }

    function sysSetRevertMessage(uint256 _input) external onlyAdmin {
        revertMessageSlot.sysSaveSlotDataUint256(_input);
    }

    function sysGetOutOfService() view public returns (uint256){
        return outOfServiceSlot.sysLoadSlotDataUint256();
    }

    function sysSetOutOfService(uint256 _input) external onlyAdmin {
        outOfServiceSlot.sysSaveSlotDataUint256(_input);
    }

    function sysGetTransparent() view public returns (uint256){
        return transparentSlot.sysLoadSlotDataUint256();
    }

    function sysSetTransparent(uint256 _input) external onlyAdmin {
        transparentSlot.sysSaveSlotDataUint256(_input);
    }

    //=====================internal functions=====================

    function sysGetNameServiceAddress() view public returns (address){
        return nameServiceAddressSlot.sysLoadSlotDataAddress();
    }

    function sysSetNameServiceAddress(address input) external onlyAdmin {
        nameServiceAddressSlot.sysSaveSlotDataAddress(input);
    }

    function sysGetNameServiceKey() view public returns (bytes32){
        return nameServiceKeySlot.sysLoadSlotData();
    }

    function sysSetNameServiceKey(bytes32 input) external onlyAdmin {
        nameServiceKeySlot.sysSaveSlotData(input);
    }

    //=====================internal functions=====================

    fallback() payable external {
        process();
    }

    receive() payable external {
        process();
    }

    function process() internal outOfService {

        if (msg.sender == sysGetAdmin() && sysGetTransparent() == 1) {
            revert("admin cann't call normal function in Transparent mode");
        }

        address nameServiceAddress = nameServiceAddressSlot.sysLoadSlotDataAddress();
        require(nameServiceAddress != address(0), "NameServiceProxy: nameService address is empty");

        bytes32 nameServiceKey = nameServiceKeySlot.sysLoadSlotData();
        require(nameServiceKey != ConstantLibrary.ZERO_BYTES, "NameServiceProxy: nameService key is empty");

        address delegator = GenericNameServiceInterface(nameServiceAddress).getSingleSafe(nameServiceKey);

        _delegate(delegator);
    }

    //!!!!do not use any memory while using _delegate()!!!!!
    function _delegate(address implementation) internal virtual {
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(), //gas
                implementation, //address
                0, //input memory offset
                calldatasize(), //input memory size
                0, //output memory offset
                0//output memory size
            )

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    //=================================================

    function sysPrintBytesToHex(bytes memory input) internal pure returns (string memory){
        bytes memory ret = new bytes(input.length * 2);
        bytes memory alphabet = "0123456789abcdef";
        for (uint256 i = 0; i < input.length; i++) {
            bytes32 t = bytes32(input[i]);
            bytes32 tt = t >> 31 * 8;
            uint256 b = uint256(tt);
            uint256 high = b / 0x10;
            uint256 low = b % 0x10;
            bytes1 highAscii = alphabet[high];
            bytes1 lowAscii = alphabet[low];
            ret[2 * i] = highAscii;
            ret[2 * i + 1] = lowAscii;
        }
        return string(ret);
    }

    function sysPrintAddressToHex(address input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintBytes4ToHex(bytes4 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintUint256ToHex(uint256 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    modifier onlyAdmin(){
        require(msg.sender == sysGetAdmin(), "only admin");
        _;
    }

    modifier outOfService(){
        if (sysGetOutOfService() == 1) {
            if (sysGetRevertMessage() == 1) {
                revert(string(abi.encodePacked("NameServiceProxy is out-of-service right now")));
            } else {
                revert();
            }
        }
        _;
    }


}
