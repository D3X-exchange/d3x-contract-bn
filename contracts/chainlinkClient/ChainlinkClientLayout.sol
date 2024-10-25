// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";

import "./ChainlinkClientType.sol";
import "../interface/chainlink/ENSInterface.sol";
import "../interface/chainlink/LinkTokenInterface.sol";
import "../interface/chainlink/ChainlinkRequestInterface.sol";
import "../interface/chainlink/OperatorInterface.sol";
import "../interface/chainlink/PointerInterface.sol";

contract ChainlinkClientLayout is
OwnableLayout,
NameServiceRefLayout {


    ENSInterface internal _s_ens;
    bytes32 internal _s_ensNode;
    LinkTokenInterface internal _s_link;
    OperatorInterface internal _s_oracle;
    uint256 internal _s_requestCount = 1;
    mapping(bytes32 => address) internal _s_pendingRequests;

}


