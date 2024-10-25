// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkClientLayout.sol";
import "../dependant/ownable/OwnableLogic.sol";
import "../nameServiceRef/NameServiceRefLogic.sol";
import "./ChainlinkClientInterface.sol";

import "./ChainlinkClientType.sol";
import "../util/Chainlink.sol";
import {ENSResolver as ENSResolver_Chainlink} from "../util/ENSResolver.sol";


contract ChainlinkClientLogic is ChainlinkClientLayout,
OwnableLogic,
NameServiceRefLogic,
ChainlinkClientInterface
{

    using Chainlink for Chainlink.Request;

    function buildChainlinkRequest(
        bytes32 _specId_,
        address _callbackAddr_,
        bytes4 _callbackFunctionSignature_
    ) internal pure returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return req.initialize(_specId_, _callbackAddr_, _callbackFunctionSignature_);
    }

    function buildOperatorRequest(
        bytes32 _specId_,
        bytes4 _callbackFunctionSignature_
    )
    internal
    view
    returns (Chainlink.Request memory)
    {
        Chainlink.Request memory req;
        return req.initialize(_specId_, address(this), _callbackFunctionSignature_);
    }

    function sendChainlinkRequest(Chainlink.Request memory _req_, uint256 _payment_) internal returns (bytes32) {
        return sendChainlinkRequestTo(address(_s_oracle), _req_, _payment_);
    }

    function sendChainlinkRequestTo(
        address _oracleAddress_,
        Chainlink.Request memory _req_,
        uint256 _payment_
    ) internal returns (bytes32 _requestId_) {
        uint256 nonce = _s_requestCount;
        _s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            ChainlinkRequestInterface.oracleRequest.selector,
            ChainlinkClientType.SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            ChainlinkClientType.AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req_.id,
            address(this),
            _req_.callbackFunctionId,
            nonce,
            ChainlinkClientType.ORACLE_ARGS_VERSION,
            _req_.buf.buf
        );
        return _rawRequest(_oracleAddress_, nonce, _payment_, encodedRequest);
    }

    function sendOperatorRequest(Chainlink.Request memory _req_, uint256 _payment_) internal returns (bytes32) {
        return sendOperatorRequestTo(address(_s_oracle), _req_, _payment_);
    }

    function sendOperatorRequestTo(
        address _oracleAddress_,
        Chainlink.Request memory _req_,
        uint256 _payment_
    ) internal returns (bytes32 _requestId_) {
        uint256 nonce = _s_requestCount;
        _s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            OperatorInterface.operatorRequest.selector,
            ChainlinkClientType.SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            ChainlinkClientType.AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req_.id,
            _req_.callbackFunctionId,
            nonce,
            ChainlinkClientType.OPERATOR_ARGS_VERSION,
            _req_.buf.buf
        );
        return _rawRequest(_oracleAddress_, nonce, _payment_, encodedRequest);
    }

    function _rawRequest(
        address _oracleAddress_,
        uint256 _nonce_,
        uint256 _payment_,
        bytes memory _encodedRequest_
    ) private returns (bytes32 _requestId_) {
        _requestId_ = keccak256(abi.encodePacked(this, _nonce_));
        _s_pendingRequests[_requestId_] = _oracleAddress_;
        emit ChainlinkRequested(_requestId_);
        require(_s_link.transferAndCall(_oracleAddress_, _payment_, _encodedRequest_), "unable to transferAndCall to oracle");
    }

    function cancelChainlinkRequest(
        bytes32 _requestId_,
        uint256 _payment_,
        bytes4 _callbackFunc_,
        uint256 _expiration_
    ) internal {
        OperatorInterface requested = OperatorInterface(_s_pendingRequests[_requestId_]);
        delete _s_pendingRequests[_requestId_];
        emit ChainlinkCancelled(_requestId_);
        requested.cancelOracleRequest(_requestId_, _payment_, _callbackFunc_, _expiration_);
    }

    function getNextRequestCount() internal view returns (uint256) {
        return _s_requestCount;
    }

    function setChainlinkOracle(address _oracleAddress_) internal {
        _s_oracle = OperatorInterface(_oracleAddress_);
    }

    function setChainlinkToken(address _linkAddress_) internal {
        _s_link = LinkTokenInterface(_linkAddress_);
    }

    function setPublicChainlinkToken() internal {
        setChainlinkToken(PointerInterface(ChainlinkClientType.LINK_TOKEN_POINTER).getAddress());
    }

    function chainlinkTokenAddress() internal view returns (address) {
        return address(_s_link);
    }

    function chainlinkOracleAddress() internal view returns (address) {
        return address(_s_oracle);
    }

    function addChainlinkExternalRequest(address _oracleAddress_, bytes32 _requestId_) internal notPendingRequest(_requestId_) {
        _s_pendingRequests[_requestId_] = _oracleAddress_;
    }

    function useChainlinkWithENS(address _ensAddress_, bytes32 _node_) internal {
        _s_ens = ENSInterface(_ensAddress_);
        _s_ensNode = _node_;
        bytes32 linkSubnode = keccak256(abi.encodePacked(_s_ensNode, ChainlinkClientType.ENS_TOKEN_SUBNAME));
        ENSResolver_Chainlink resolver = ENSResolver_Chainlink(_s_ens.resolver(linkSubnode));
        setChainlinkToken(resolver.addr(linkSubnode));
        updateChainlinkOracleWithENS();
    }

    function updateChainlinkOracleWithENS() internal {
        bytes32 oracleSubnode = keccak256(abi.encodePacked(_s_ensNode, ChainlinkClientType.ENS_ORACLE_SUBNAME));
        ENSResolver_Chainlink resolver = ENSResolver_Chainlink(_s_ens.resolver(oracleSubnode));
        setChainlinkOracle(resolver.addr(oracleSubnode));
    }

    function validateChainlinkCallback(bytes32 _requestId_)
    internal
    recordChainlinkFulfillment(_requestId_)
        // solhint-disable-next-line no-empty-blocks
    {

    }

    modifier recordChainlinkFulfillment(bytes32 _requestId_) {
        require(msg.sender == _s_pendingRequests[_requestId_], "Source must be the oracle of the request");
        delete _s_pendingRequests[_requestId_];
        emit ChainlinkFulfilled(_requestId_);
        _;
    }

    modifier notPendingRequest(bytes32 _requestId_) {
        require(_s_pendingRequests[_requestId_] == address(0), "Request is already pending");
        _;
    }
}
