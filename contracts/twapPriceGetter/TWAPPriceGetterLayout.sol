// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dependant/ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";

import "./TWAPPriceGetterType.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract TWAPPriceGetterLayout is
OwnableLayout,
NameServiceRefLayout {

    //uint constant PRECISION = 1e10;
    //uint internal _precision;
    //https://arbiscan.io/address/0x18c11FD286C5EC11c3b683Caa813B77f5163A122  GNS
    //address internal _token;

    // Adjustable parameters
    //https://arbiscan.io/address/0x4d2fE06Fd1c4368042B926D082484D2E3cC8F3F5#code  就是dai<>gns的池子
    //IUniswapV3Pool internal _uniV3Pool;
    //3600
    //uint32 internal _twapInterval;

    // State
    //true
    //bool internal _isGnsToken0InLp;


    mapping(address => TWAPPriceGetterType.PoolConfig) internal _poolConfig;
}


