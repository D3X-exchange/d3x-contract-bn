// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/dependant/ownable/OwnableInterface.sol";
import "contracts/nameServiceRef/NameServiceRefInterface.sol";
import "../chainlinkClient/ChainlinkClientInterface.sol";
import "../twapPriceGetter/TWAPPriceGetterInterface.sol";
import "./D3xManagerEvent.sol";

import "./D3xManagerType.sol";

interface D3xManagerInterface6 is
    //here select needed interface
OwnableInterface,
NameServiceRefInterface,
//ChainlinkClientInterface,
//TWAPPriceGetterInterface,
D3xManagerEvent {

    function updatePendingTradeLimit(
        uint64 tradeNumber,
        uint64 desiredOpenPrice,
        uint64 desiredTp,
        bool isSlSet,
        uint64 desiredSl,
        uint24 slippageFactorInExtraPoint
    ) external;

    function getTradeTpSlMax(
        uint64 tradeNumber
    ) external view returns (uint64 extremeTp, uint64 extremeSl);

    function calcTpSlPrice(
        uint64 openPrice,
        bool long,
        uint8 leverage,
        uint16 percent /*900*/,
        bool tp
    ) external pure returns (uint64);

    function calcTpSlMax(
        uint64 price,
        bool long,
        uint8 leverage
    ) external pure returns (uint64 extremeTp, uint64 extremeSl);

    function updateTradeTpSlLive(
        uint64 tradeNumber,
        uint64 newTp,
        bool newIsSlSet,
        uint64 newSl
    ) external;

    function getLiqPrice(
        uint64[] calldata tradeNumber
    ) external view returns (uint64[] memory liqPrice);

    function calcLiqPrice(
        uint64 openPrice,
        bool long,
        uint128 collateral,
        uint8 leverage,
        uint64 borrowingFee
    ) external pure returns (uint64 liqPrice);

    function calcBorrowingFee(uint64 tradeNumber) external view returns (uint128 borrowingFee);

    function claimOracleFee(address currency) external;

    function claimTriggerFee(address currency) external;

    function getPairCurrencyFeeRatePerDayNow(uint16 pairCurrencyNumber) external view returns (
        uint256 borrowingFeeRatePerDayForLong,
        uint256 borrowingFeeRatePerDayForShort
    );

    function faucet(address currency) external;

    function transferBack(address tokenAddress, address to, uint256 amount) external;
}
