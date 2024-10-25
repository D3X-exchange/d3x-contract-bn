// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TWAPPriceGetterType {

    // Constants
    uint32 internal constant MIN_TWAP_PERIOD = 1 hours / 2;
    uint32 internal constant MAX_TWAP_PERIOD = 4 hours;

    uint256 internal constant PRECISION = 1e10; // 10 decimals

    //base/quote
    //the base is always D3x
    //the quote is what configured here
    struct PoolConfig{
        address quoteCurrency;
        address uniV3Pool;
        uint256 twapInterval;
        //for inverse
        bool isD3xToken0;
    }
}
