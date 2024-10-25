// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafetyBoxLayout.sol";
import "../dependant/safetyBox/GenericSafetyBoxLogic.sol";
import "../nameServiceRef/NameServiceRefLogic.sol";
import "./SafetyBoxInterface.sol";

// asset vault
contract SafetyBoxLogic is Delegate, SafetyBoxLayout, GenericSafetyBoxLogic, NameServiceRefLogic, SafetyBoxInterface {

    function defaultFallback() override virtual internal {
        if (msg.value > 0) {
            returnAsm(false, "");
        }
        returnAsm(false, notFoundMark);
    }

}
