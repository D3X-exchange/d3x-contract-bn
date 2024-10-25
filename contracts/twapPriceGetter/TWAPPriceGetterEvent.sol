// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TWAPPriceGetterType.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface TWAPPriceGetterEvent {

    // Events
    event UniV3PoolUpdated(IUniswapV3Pool newValue);
    event TwapIntervalUpdated(uint32 newValue);

}
