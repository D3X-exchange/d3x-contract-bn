// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericVRFCenterLayout.sol";
import "../ownable/OwnableLogic.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "./GenericVRFCenterInterface.sol";

import "../helperLibrary/vrfLibrary/VRF.sol";
import "../helperLibrary/ConstantLibrary.sol";

//https://github.com/cbrpunks/vrf-ts-256
contract GenericVRFCenterLogic is GenericVRFCenterLayout, OwnableLogic, GenericNameServiceRefLogic, GenericVRFCenterInterface {

    function requestVrf(address who, bytes32 reason) override external returns (bytes32 /*requestId*/) {
        uint256 nonce = _vrfTriple[msg.sender][who][reason];

        //fix alpha as bytes32 as requestId
        bytes32 alpha = keccak256(abi.encode(msg.sender, who, reason, nonce, _vrfGlobalNonce));
        require(!_vrfAlphaString[alpha], "vrf center: request id duplicated, or has been requested");
        _vrfAlphaString[alpha] = true;
        _vrfCallBack[alpha] = msg.sender;

        _vrfTriple[msg.sender][who][reason] = nonce + 1;
        _vrfGlobalNonce = _vrfGlobalNonce + 1;

        emit RequestVRF(alpha);

        return alpha;
    }

    //do remember to lock 'something' first
    function verifyVrf(
        GenericVRFCenterType.VerifyParam calldata param
    ) override external returns (bytes32 randomness){
        return _verifyVrf(param);
    }

    //feed = self give proof and get randomness
    function _verifyVrf(
        GenericVRFCenterType.VerifyParam calldata param
    ) internal returns (bytes32 randomness){

        require(_vrfAlphaString[param.requestId], "vrf center: request id has not been requested");

        if (_vrfBetaString[param.requestId] != bytes32(0)) {
            return _vrfBetaString[param.requestId];
        }

        address vrfProvider = publicKeyToAddress(param.publicKey);
        require(vrfSigner() == vrfProvider, "vrf center: vrf provider is invalid");

        //verify the proof
        require(
            VRF.fastVerify(
                param.publicKey,
                param.proof,
                abi.encodePacked(param.requestId),
                param.uPoint,
                param.vComponents
            ),
            "vrf center: vrf proof verify fails"
        );

        randomness = VRF.gammaToHash(param.proof[0], param.proof[1]);
        _vrfBetaString[param.requestId] = randomness;

        emit VerifyVRF(param.requestId, randomness);

        address callBack = _vrfCallBack[param.requestId];
        require(callBack != address(0), "vrf center: call back address is zero");
        require(callBack == msg.sender, "vrf center: verify vrf callBack should be requester as proactive invoke");

        return randomness;
    }

    function feedVrf(
        GenericVRFCenterType.VerifyParam calldata param
    ) override external {
        _feedVrf(param);
    }

    function feedVrfs(
        GenericVRFCenterType.VerifyParam[] calldata params
    ) override external {
        for (uint256 i = 0; i < params.length; i++) {
            _feedVrf(params[i]);
        }
    }

    //feed = server give proof and callback
    function _feedVrf(
        GenericVRFCenterType.VerifyParam calldata param
    ) internal {

        require(_vrfAlphaString[param.requestId], "vrf center: request id has not been requested");

        if (_vrfBetaString[param.requestId] != bytes32(0)) {
            //already fed, no need to call 'callback' again
            return;
        }

        address vrfProvider = publicKeyToAddress(param.publicKey);
        require(vrfSigner() == vrfProvider, "vrf center: vrf provider is invalid");

        //verify the proof
        require(
            VRF.fastVerify(
                param.publicKey,
                param.proof,
                abi.encodePacked(param.requestId),
                param.uPoint,
                param.vComponents
            ),
            "vrf center: vrf proof verify fails"
        );

        bytes32 randomness = VRF.gammaToHash(param.proof[0], param.proof[1]);
        _vrfBetaString[param.requestId] = randomness;

        emit FeedVRF(param.requestId, randomness);

        address callBack = _vrfCallBack[param.requestId];
        require(callBack != address(0), "vrf center: call back address is zero");
        require(callBack != msg.sender, "vrf center: feed vrf callBack should not be request");

        (bool success, bytes memory returnData) = address(callBack).call(abi.encodeWithSignature("rawFulfillRandomness(bytes32,bytes32)", param.requestId, randomness));
        success;
        returnData;
    }

    function stuffVrf(
        GenericVRFCenterType.StuffParam calldata param
    ) override external {
        _stuffVrf(param);

    }

    function stuffVrfs(
        GenericVRFCenterType.StuffParam[] calldata params
    ) override external {
        for (uint256 i = 0; i < params.length; i++) {
            _stuffVrf(params[i]);
        }
    }

    //stuff = server give randomness and callback
    function _stuffVrf(
        GenericVRFCenterType.StuffParam calldata param
    ) internal {

        require(param.randomness != ConstantLibrary.ZERO_BYTES, "vrf center: stuff randomness is empty");

        require(_vrfAlphaString[param.requestId], "vrf center: request id has not been requested");

        if (_vrfBetaString[param.requestId] != bytes32(0)) {
            //already stuffed, no need to call 'callback' again
            return;
        }

        require(msg.sender == vrfSigner(), "vrf center: stuff only accepts vrf signer");

        _vrfBetaString[param.requestId] = param.randomness;

        emit StuffVRF(param.requestId, param.randomness);

        address callBack = _vrfCallBack[param.requestId];
        require(callBack != address(0), "vrf center: call back address is zero");
        require(callBack != msg.sender, "vrf center: stuff vrf callBack should not be request");

        (bool success, bytes memory returnData) = address(callBack).call(abi.encodeWithSignature("rawFulfillRandomness(bytes32,bytes32)", param.requestId, param.randomness));
        success;
        returnData;
    }


    function vrfAlphaString(bytes32 requestId) override view external returns (bool){
        return _vrfAlphaString[requestId];
    }

    function vrfBetaString(bytes32 requestId) override view external returns (bytes32){
        return _vrfBetaString[requestId];
    }

    function publicKeyToAddress(uint256[2] memory publicKey) override pure public returns (address){
        bytes32 x = bytes32(publicKey[0]);
        bytes32 y = bytes32(publicKey[1]);

        bytes memory pub = abi.encodePacked(x, y);

        return address(uint160(uint256(keccak256(pub))));
    }
}
