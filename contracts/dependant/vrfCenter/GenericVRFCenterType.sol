// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GenericVRFCenterType {

    struct VerifyParam {
        bytes32 requestId; //alpha
        uint256[2] publicKey; //Y:x, Y:y
        uint256[4] proof; //D, a.k.a.decoded Pi, Gamma:x, Gamma:y, c, s
        uint256[2] uPoint; //U:x, U:y
        uint256[4] vComponents;//s*H:x, s*H:y, c*Gamma:x, c*Gamma:y
    }

    struct StuffParam {
        bytes32 requestId;
        bytes32 randomness;
    }
}
