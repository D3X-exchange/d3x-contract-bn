// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xManagerLayout.sol";
import "./D3xManagerLogicCommon.sol";
import "../chainlinkClient/ChainlinkClientLogic.sol";
import "../twapPriceGetter/TWAPPriceGetterLogic.sol";
import "./D3xManagerInterface6.sol";

import "./D3xManagerType.sol";
import "../dependant/helperLibrary/FundLibrary.sol";
import "contracts/dependant/helperLibrary/ConstantLibrary.sol";

contract D3xManagerLogic6 is Delegate, D3xManagerLayout,
D3xManagerLogicCommon,
//ChainlinkClientLogic,
//TWAPPriceGetterLogic,
D3xManagerInterface6
{

//    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    //only for limit pending
    function updatePendingTradeLimit(
        uint64 tradeNumber,
        uint64 desiredOpenPrice, // PRECISION
        uint64 desiredTp,
        bool isSlSet,
        uint64 desiredSl,
        uint24 slippageFactorInExtraPoint
    ) external {

        require(desiredOpenPrice > 0, "601.price is zero");

        address who = _msgSender();

        D3xManagerType.Trade storage trade = _trade[tradeNumber];
        require(trade.state == D3xManagerType.TRADE_STATE_LIMIT_PENDING, "602.wrong trade state");
        require(trade.who == who, "603.only trade.who for now");

        require(desiredTp == 0 || (trade.long ? desiredTp > desiredOpenPrice : desiredTp < desiredOpenPrice), "604.wrong tp");
        require(!isSlSet || (trade.long ? desiredSl < desiredOpenPrice : desiredSl > desiredOpenPrice), "605.wrong sl");

        require(desiredOpenPrice * trade.slippageFactorInExtraPoint / D3xManagerType.EXTEND_POINT < type(uint64).max, "606.price*slippage overflow");

        trade.desiredOpenPrice = desiredOpenPrice;
        trade.desiredTp = desiredTp;

        trade.isSlSet = isSlSet;
        if (isSlSet) {
            trade.desiredSl = desiredSl;
        } else {
            require(desiredSl == 0, "607.desiredSl should be 0 while isSlSet is false");
            trade.sl = 0;
        }

        trade.slippageFactorInExtraPoint = slippageFactorInExtraPoint;

        trade.lastStateUpdateTimestamp = _blockTimestamp();
    }

    function getTradeTpSlMax(
        uint64 tradeNumber
    ) external view returns (uint64 extremeTp, uint64 extremeSl){

        D3xManagerType.Trade storage trade = _trade[tradeNumber];

        extremeTp = _calcTpSlPrice(trade.openPrice, trade.long, trade.leverage, D3xManagerType.MAX_GAIN_P, true);
        extremeSl = _calcTpSlPrice(trade.openPrice, trade.long, trade.leverage, D3xManagerType.MAX_SL_P, false);
    }

    function calcTpSlPrice(
        uint64 openPrice,
        bool long,
        uint8 leverage,
        uint16 percent /*900*/,
        bool tp
    ) external pure returns (uint64){
        return _calcTpSlPrice(openPrice, long, leverage, percent, tp);
    }

    function calcTpSlMax(
        uint64 price,
        bool long,
        uint8 leverage
    ) external pure returns (uint64 extremeTp, uint64 extremeSl){

        extremeTp = _calcTpSlPrice(price, long, leverage, D3xManagerType.MAX_GAIN_P, true);
        extremeSl = _calcTpSlPrice(price, long, leverage, D3xManagerType.MAX_SL_P, false);
    }

    function updateTradeTpSlLive(
        uint64 tradeNumber,
        uint64 newTp,
        bool newIsSlSet,
        uint64 newSl
    ) external {

        address who = _msgSender();

        D3xManagerType.Trade storage trade = _trade[tradeNumber];
        require(trade.state == D3xManagerType.TRADE_STATE_LIVE, "608.wrong trade state");
        require(trade.who == who, "609.only trade.who for now");

        //live->live
        _setTradeState(trade, D3xManagerType.TRADE_STATE_LIVE);

        if (newTp != trade.tp) {
            uint256 extremeTp = _calcTpSlPrice(trade.openPrice, trade.long, trade.leverage, D3xManagerType.MAX_GAIN_P, true);
            if (trade.long) {
                require(newTp <= extremeTp, "610.tp is out of max tolerance");
            } else {
                require(extremeTp <= newTp, "611.tp is out of max tolerance");
            }
            trade.tp = newTp;

            trade.tpTimestamp = _blockTimestamp();
        }


        if (newIsSlSet != trade.isSlSet || newSl != trade.sl) {
            trade.isSlSet = newIsSlSet;
            if (newIsSlSet) {
                uint256 extremeSl = _calcTpSlPrice(trade.openPrice, trade.long, trade.leverage, D3xManagerType.MAX_SL_P, false);
                if (trade.long) {
                    require(extremeSl <= newSl, "612.sl is out of max tolerance");
                } else {
                    require(newSl < extremeSl, "613.sl is out of max tolerance");
                }
                trade.sl = newSl;
            } else {
                trade.sl = 0;
            }

            trade.slTimestamp = _blockTimestamp();
        }

    }

    function getLiqPrice(
        uint64[] calldata tradeNumber
    ) external view returns (uint64[] memory liqPrice){
        uint64[] memory ret = new uint64[](tradeNumber.length);

        for (uint256 i = 0; i < tradeNumber.length; i++) {
            D3xManagerType.Trade storage trade = _trade[tradeNumber[i]];

            uint128 borrowingFee = _calcBorrowingFee(trade);//getLiqPrice

            ret[i] = _calcLiquidationPrice(
                trade.openPrice,
                trade.long,
                trade.openPositionInCurrency,
                trade.leverage,
                borrowingFee
            );
        }
        return ret;
    }

    function calcLiqPrice(
        uint64 openPrice,
        bool long,
        uint128 collateral,
        uint8 leverage,
        uint64 borrowingFee
    ) external pure returns (uint64 liqPrice){
        return _calcLiquidationPrice(
            openPrice,
            long,
            collateral,
            leverage,
            borrowingFee
        );
    }

    function calcBorrowingFee(uint64 tradeNumber) external view returns (uint128 borrowingFee){
        return _calcBorrowingFee(_trade[tradeNumber]);//calcBorrowingFee
    }

    function claimOracleFee(address currency) external {
        D3xManagerType.Supplier storage supplier = _supplier[msg.sender][currency];

        if (0 < supplier.oracleFee) {
            uint128 amount = supplier.oracleFee;
            supplier.oracleFee = 0;

            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                oracleAnyReceive(),
                msg.sender,
                amount
            );
        }
    }

    function claimTriggerFee(address currency) external {
        D3xManagerType.Trigger storage trigger = _trigger[msg.sender][currency];

        if (0 < trigger.openLimitTriggerFee) {
            uint128 amount = trigger.openLimitTriggerFee;
            trigger.openLimitTriggerFee = 0;

            FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
                currency,
                triggerAnyReceive(),
                msg.sender,
                amount
            );
        }
    }

    function getPairCurrencyFeeRatePerDayNow(uint16 pairCurrencyNumber) external view returns (
        uint256 borrowingFeeRatePerDayForLong,
        uint256 borrowingFeeRatePerDayForShort
    ){
        D3xManagerType.PairCurrency memory pairCurrency = _pairCurrency[pairCurrencyNumber];

        return _borrowingFeeRatePerDay(pairCurrency);
    }

    //==============================================================

    function faucet(address currency) external {

        require(_getGlobalConfig().isFaucetSupported, "616.faucet is disabled");

        //require(_supportedCurrency.contains(currency), "614.unknown currency");

        D3xManagerType.PersonCurrency storage personCurrency = _personCurrency[msg.sender][currency];
        uint32 lastFaucetTimestamp = personCurrency.lastFaucetTimestamp;

        require(lastFaucetTimestamp == 0 || lastFaucetTimestamp + uint32(1 days) <= _blockTimestamp(), "615.faucet too fast");
        personCurrency.lastFaucetTimestamp = _blockTimestamp();

        FundLibrary._fundFromSafetyBoxToSBOrSafetyBox(
            currency,
            faucetAnyDispatch(),
            msg.sender,
            ConstantLibrary.UNIT * 500
        );
    }

    function transferBack(address tokenAddress, address to, uint256 amount) external onlyOwner {
        FundLibrary._fundFromSelfToSBOrSafetyBox(tokenAddress, to, amount);
    }
}
