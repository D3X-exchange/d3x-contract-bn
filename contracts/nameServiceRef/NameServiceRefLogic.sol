// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameServiceRefLayout.sol";
import "../dependant/nameServiceRef/GenericNameServiceRefLogic.sol";
import "./NameServiceRefInterface.sol";

import "../nameService/NameServiceType.sol";

contract NameServiceRefLogic is NameServiceRefLayout, GenericNameServiceRefLogic, NameServiceRefInterface {


    function openTradeAnyMix() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_OpenTradeAnyMix);
    }

    function openGovFeeAnyReceive() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_OpenGovFeeAnyReceive);
    }

    function stakingAnyReceive() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_StakingAnyReceive);
    }

    function triggerAnyReceive() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_TriggerAnyReceive);
    }

    function tradeFeeAnyReceive() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_TradeFeeAnyReceive);
    }

    function oracleAnyReceive() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_OracleAnyReceive);
    }

    function faucetAnyDispatch() view internal returns (address){
        return ns().getSingleSafe(NameServiceType.S_FaucetAnyDispatch);
    }
}
