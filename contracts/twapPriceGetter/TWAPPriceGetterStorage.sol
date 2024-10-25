// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TWAPPriceGetterLayout.sol";
import "../dependant/ownable/OwnableStorage.sol";
import "../nameServiceRef/NameServiceRefStorage.sol";

import "./TWAPPriceGetterType.sol";

abstract contract TWAPPriceGetterStorage is Proxy,
TWAPPriceGetterLayout,
OwnableStorage,
NameServiceRefStorage {

    constructor (
//        IUniswapV3Pool _uniV3Pool_,
//        uint32 _twapInterval_,
//        uint _precision_

    /*address nameService_,
    address owner_*/
    )
//    Proxy(msg.sender)
        /*OwnableStorage(owner_)
        NameServiceRefStorage(nameService_)*/{

        /*require(
            address(_uniV3Pool_) != address(0) &&
            _twapInterval_ >= TWAPPriceGetterType.MIN_TWAP_PERIOD &&
            _twapInterval_ <= TWAPPriceGetterType.MAX_TWAP_PERIOD &&
            _precision_ > 0,
            "WRONG_TWAP_CONSTRUCTOR"
        );

        _uniV3Pool = _uniV3Pool_;
        _twapInterval = _twapInterval_;
        _precision = _precision_;

        _isGnsToken0InLp = _uniV3Pool.token0() == _token_;*/

    }
}
