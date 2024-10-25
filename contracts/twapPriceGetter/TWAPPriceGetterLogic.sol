// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TWAPPriceGetterLayout.sol";
import "../dependant/ownable/OwnableLogic.sol";
import "../nameServiceRef/NameServiceRefLogic.sol";
import "./TWAPPriceGetterInterface.sol";

import "./TWAPPriceGetterType.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../util/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "../util/FullMath.sol";

contract TWAPPriceGetterLogic is Delegate, TWAPPriceGetterLayout,
OwnableLogic,
NameServiceRefLogic,
TWAPPriceGetterInterface
{


    // Returns price with "precision" decimals
    // https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol
    //tokenPriceDai(GNS price Dai)
    /*function d3xPriceInUsdt() public view virtual returns (uint price) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = _twapInterval;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = _uniV3Pool.observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int56 twapIntervalInt = int56(int32(_twapInterval));

        int24 arithmeticMeanTick = int24(tickCumulativesDelta / twapIntervalInt);
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % twapIntervalInt != 0)
        ) {
            //如果tick是下跌的,那么不能用0来表示,因为0表示tick是上涨的,变成-1
            arithmeticMeanTick--;
        }

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);
        price = (FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96) * _precision) / 2 ** 96;

        if (!_isGnsToken0InLp) {
            price = _precision ** 2 / price;
        }
    }*/

    function d3xPriceInX(address inCurrency) external view returns (uint256 price) {

        TWAPPriceGetterType.PoolConfig storage poolConfig = _poolConfig[inCurrency];
        require(poolConfig.quoteCurrency == inCurrency,"TWAPPrice, currency not found");



        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = uint32(poolConfig.twapInterval);
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(poolConfig.uniV3Pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int56 twapIntervalInt = int56(int256(poolConfig.twapInterval));

        int24 arithmeticMeanTick = int24(tickCumulativesDelta / twapIntervalInt);
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % twapIntervalInt != 0)
        ) {
            //如果tick是下跌的,那么不能用0来表示,因为0表示tick是上涨的,变成-1
            arithmeticMeanTick--;
        }

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);
        price = (FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96) * TWAPPriceGetterType.PRECISION) / 2 ** 96;

        if (!poolConfig.isD3xToken0) {
            price = TWAPPriceGetterType.PRECISION ** 2 / price;
        }
    }


    function setPoolConfig(TWAPPriceGetterType.PoolConfig[] calldata addConfig, address[] calldata removeConfig) onlyOwner external{
        for (uint256 i = 0; i < addConfig.length; i++) {
            TWAPPriceGetterType.PoolConfig calldata needAdd = addConfig[i];

            require(
                TWAPPriceGetterType.MIN_TWAP_PERIOD <= needAdd.twapInterval &&
                needAdd.twapInterval <= TWAPPriceGetterType.MAX_TWAP_PERIOD,
                "WRONG_VALUE"
            );

            _poolConfig[needAdd.quoteCurrency] = needAdd;
        }

        for (uint256 i = 0; i < removeConfig.length; i++) {
            delete _poolConfig[removeConfig[i]];
        }
    }
}
