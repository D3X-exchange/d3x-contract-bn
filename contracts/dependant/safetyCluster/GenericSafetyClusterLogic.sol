// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GenericSafetyClusterLayout.sol";
import "../ownable/OwnableLogic.sol";
import "../nameServiceRef/GenericNameServiceRefLogic.sol";
import "../holders/HERC1155HolderLogic.sol";
import "../holders/HERC721HolderLogic.sol";
import "./GenericSafetyClusterInterface.sol";

import "../safetyPlanet/GenericSafetyPlanetInterface.sol";
import "../safetyPlanet/GenericSafetyPlanetStorage.sol";

// asset vault
//the contract itself won't hold any tokens and nfts
abstract contract GenericSafetyClusterLogic is GenericSafetyClusterLayout, OwnableLogic, GenericNameServiceRefLogic, HERC1155HolderLogic, HERC721HolderLogic, GenericSafetyClusterInterface {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function _onlyAuthTrusted() virtual internal override view returns (bool){
        return isAuth() || ns().isTrusted(msg.sender);
    }

    //must transfer to manager first, then hand over to cluster
    //this is because the user only give allowance to manager, not to safetyCluster
    function giveErc20(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256 amount
    ) override external payable onlyAuthTrusted {

        _interactedErc20Tokens.add(tokenAddress);
        _interactedCategory.add(category);

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(true);
        (GenericSafetyClusterType.PlanetInfo storage planetInfo,) = _next(iter, true, true);

        //transfer fund to that planet
        uint256 balanceTransferred = _transfer20FromOutToPlanet(category, tokenAddress, msg.sender, planetInfo, amount);

        _appendBill(category, tokenAddress, true, fakeFrom, "Erc20", amount, balanceTransferred, new uint256[](0));
    }

    function takeErc20(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256 amount
    ) override external onlyAuthTrusted {

        require(amount <= _categoryErc20Balance[category][tokenAddress], "insufficient erc20 balance for category and token");

        uint256 amountNeed = amount;

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(true);

        while (0 < amountNeed) {
            //try take amount from planet

            (GenericSafetyClusterType.PlanetInfo storage planetInfo,) = _next(iter, true, false);

            if (planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_UNDEPLOYED) {
                continue;
            }

            uint256 amountTaken = Math.min(amountNeed, _planetErc20Balance[planetInfo.planetIndex][tokenAddress]);

            amountNeed -= amountTaken;
            _transfer20FromPlanetToOut(category, tokenAddress, planetInfo, to, amountTaken);
        }

        _appendBill(category, tokenAddress, false, to, "Erc20", amount, amount, new uint256[](0));

    }

    function moveErc20(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256 amount
    ) override external onlyAuthTrusted {
        require(amount <= _categoryErc20Balance[fromCategory][tokenAddress], "moveErc20, insufficient erc20 balance for category and token");

        _categoryErc20Balance[fromCategory][tokenAddress] -= amount;
        _categoryErc20Balance[toCategory][tokenAddress] += amount;

        //emu take
        _appendBill(fromCategory, tokenAddress, false, fakeTo, "Erc20", amount, amount, new uint256[](0));
        //emu give
        _appendBill(toCategory, tokenAddress, true, fakeFrom, "Erc20", amount, amount, new uint256[](0));

    }

    function giveErc721(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256 nftId
    ) override external onlyAuthTrusted {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nftId;

        _giveErc721(category, tokenAddress, fakeFrom, nftIds);
    }

    //avoid overload for js/ts indexed field to get function
    function giveErc721s(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256[] calldata nftIds
    ) override external onlyAuthTrusted {
        _giveErc721(category, tokenAddress, fakeFrom, nftIds);
    }

    function _giveErc721(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256[] memory nftIds
    ) internal {

        _interactedErc721Tokens.add(tokenAddress);
        _interactedCategory.add(category);

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(true);

        (GenericSafetyClusterType.PlanetInfo storage planetInfo,) = _next(iter, true, true);

        //transfer fund to that planet
        _transfer721FromOutToPlanet(category, tokenAddress, msg.sender, planetInfo, nftIds);

        _appendBill(category, tokenAddress, true, fakeFrom, "Erc721", nftIds.length, 0, nftIds);
    }

    function takeErc721(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256 nftId
    ) override external onlyAuthTrusted {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nftId;

        _transfer721FromPlanetToOut(category, tokenAddress, to, nftIds);

        _appendBill(category, tokenAddress, false, to, "Erc721", 1, 0, nftIds);

    }

    function takeErc721s(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256[] calldata nftIds
    ) override external onlyAuthTrusted {

        _transfer721FromPlanetToOut(category, tokenAddress, to, nftIds);

        _appendBill(category, tokenAddress, false, to, "Erc721", nftIds.length, 0, nftIds);
    }

    function moveErc721(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256 nftId
    ) override external onlyAuthTrusted {

        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nftId;

        _moveErc721s(fromCategory, toCategory, tokenAddress, fakeTo, fakeFrom, nftIds);
    }

    function moveErc721s(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256[] calldata nftIds
    ) override external onlyAuthTrusted {
        _moveErc721s(fromCategory, toCategory, tokenAddress, fakeTo, fakeFrom, nftIds);
    }

    function _moveErc721s(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256[] memory nftIds
    ) internal {

        require(nftIds.length <= _categoryErc721Balance[fromCategory][tokenAddress], "_moveErc721, category nft balance is not enough");
        _categoryErc721Balance[fromCategory][tokenAddress] -= nftIds.length;
        _categoryErc721Balance[toCategory][tokenAddress] += nftIds.length;

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            require(_planetErc721NftTracker[tokenAddress][nftId] != 0, "_moveErc721, missing nft");

        }
        //emu take
        _appendBill(fromCategory, tokenAddress, false, fakeTo, "Erc721", nftIds.length, 0, nftIds);

        //emu give
        _appendBill(toCategory, tokenAddress, true, fakeFrom, "Erc721", nftIds.length, 0, nftIds);

    }

    function giveErc1155(
        bytes32 category,
        address tokenAddress,
        address fakeFrom,
        uint256 id,
        uint256 amount
    ) override external onlyAuthTrusted {
        _interactedErc1155Tokens.add(tokenAddress);
        _interactedCategory.add(category);

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(true);
        (GenericSafetyClusterType.PlanetInfo storage planetInfo,) = _next(iter, true, true);

        //transfer fund to that planet
        _transfer1155FromOutToPlanet(category, tokenAddress, msg.sender, planetInfo, id, amount);

        _appendBill(category, tokenAddress, true, fakeFrom, "Erc1155", amount, id, new uint256[](0));

    }

    function takeErc1155(
        bytes32 category,
        address tokenAddress,
        address to,
        uint256 id,
        uint256 amount
    ) override external onlyAuthTrusted {

        require(amount <= _categoryErc1155Balance[category][tokenAddress][id], "takeErc1155, insufficient erc1155 balance for category and token");

        uint256 amountNeed = amount;

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(true);

        while (0 < amountNeed) {
            //try take amount from planet

            (GenericSafetyClusterType.PlanetInfo storage planetInfo,) = _next(iter, true, false);

            if (planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_UNDEPLOYED) {
                continue;
            }

            uint256 amountTaken = Math.min(amountNeed, _planetErc1155Balance[planetInfo.planetIndex][tokenAddress][id]);

            amountNeed -= amountTaken;
            _transfer1155FromPlanetToOut(category, tokenAddress, planetInfo, to, id, amountTaken);
        }


        _appendBill(category, tokenAddress, false, to, "Erc1155", amount, id, new uint256[](0));
    }

    function moveErc1155(
        bytes32 fromCategory,
        bytes32 toCategory,
        address tokenAddress,
        address fakeTo,
        address fakeFrom,
        uint256 id,
        uint256 amount
    ) override external onlyAuthTrusted {

        require(amount <= _categoryErc1155Balance[fromCategory][tokenAddress][id], "moveErc1155, insufficient erc1155 balance for category and token");
        _categoryErc1155Balance[fromCategory][tokenAddress][id] -= amount;
        _categoryErc1155Balance[toCategory][tokenAddress][id] += amount;

        //emu take
        _appendBill(fromCategory, tokenAddress, false, fakeTo, "Erc1155", amount, id, new uint256[](0));
        //emu give
        _appendBill(toCategory, tokenAddress, true, fakeFrom, "Erc1155", amount, id, new uint256[](0));

    }

    function _planetIterator(bool randomStart) internal returns (GenericSafetyClusterType.PlanetIterator memory){

        uint256 planetCount = _config[0].planetCount;
        require(planetCount == _activePlanetIndex.length(), "random planet, planet count and active planet length mismatch");
        require(0 < planetCount, "no planets at all");

        uint256 activePlanetOffset;
        if (randomStart) {
            activePlanetOffset = _fitRange(_randomSeedDex(), 0, planetCount);
        } else {
            activePlanetOffset = 0;
        }

        GenericSafetyClusterType.PlanetIterator memory iter = GenericSafetyClusterType.PlanetIterator(
            type(uint256).max,
            activePlanetOffset,
            planetCount
        );
        return iter;
    }

    //safe=true for throw exception while trying to iterate again
    //or infinite loop and returns success=false while first hit the start
    function _next(GenericSafetyClusterType.PlanetIterator memory _iter_, bool safe, bool needBirth) internal returns (GenericSafetyClusterType.PlanetInfo storage ret, bool success){
        if (_iter_._activePlanetOffsetCursor == type(uint256).max) {
            _iter_._activePlanetOffsetCursor = _iter_._activePlanetOffsetOriginal;
        } else {
            uint256 newCursor = _iter_._activePlanetOffsetCursor + 1;
            if (_iter_._activePlanetOffsetLength <= newCursor) {
                newCursor = newCursor % _iter_._activePlanetOffsetLength;
            }

            if (newCursor == _iter_._activePlanetOffsetOriginal) {
                //hit the start
                if (safe) {
                    revert("planet iterator ends");
                } else {
                    //not allow dangling pointer :(
                    return (_planetInfo[type(uint256).max], false);
                }
            }

            _iter_._activePlanetOffsetCursor = newCursor;
        }

        uint256 planetIndex = _activePlanetIndex.at(_iter_._activePlanetOffsetCursor);
        ret = _preparePlanet(planetIndex, needBirth);
        return (ret, true);

    }

    function _preparePlanet(uint256 planetIndex, bool needBirth)
    internal returns (GenericSafetyClusterType.PlanetInfo storage){
        GenericSafetyClusterType.PlanetInfo storage planetInfo = _planetInfo[planetIndex];

        if (planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_UNDEPLOYED) {

            if (needBirth) {
                planetInfo.planetIndex = planetIndex;
                planetInfo.planetAddress = _deployPlanet();
                planetInfo.status = GenericSafetyClusterType.PLANET_STATUS_NORMAL;
            } else {
                //as-is
            }

        } else if (planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_NORMAL) {
            //fine
            require(planetInfo.planetIndex == planetIndex, "prepare planet, planet index mismatches");
            require(planetInfo.planetAddress != address(0), "prepare planet, planet address is empty");
        } else if (planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_OBSOLETE) {
            revert("trying send fund to obsolete planet");
        } else {
            revert("trying send fund to unknown status planet");
        }

        return planetInfo;
    }

    function _deployPlanet() internal virtual returns (address);

    /*function _deployPlanet() internal returns (address){

        GenericSafetyPlanetStorage newGenericSafetyPlanetStorage = new GenericSafetyPlanetStorage(
        //don't forget set the safety planet logic address to name service
            GenericNameServiceType.S_GenericSafetyPlanetLogic,
            address(ns()),
            owner()//NameServiceProxy's admin is operator
        );

        return address(newGenericSafetyPlanetStorage);
    }*/


    function _fitRangeInclude(uint256 input, uint256 min, uint256 max) pure internal returns (uint256){
        require(min <= max, "min <= max");

        if (min == max) {
            return min;
        } else {
            uint256 range = max - min + 1;
            uint256 number = input % range;
            return min + number;
        }
    }

    function _fitRange(uint256 input, uint256 min, uint256 max) pure internal returns (uint256){
        require(min < max, "min < max");

        if (min + 1 == max) {
            return min;
        } else {
            uint256 range = max - min;
            uint256 number = input % range;
            return min + number;
        }
    }

    function _randomSeedDex() internal returns (uint256){

        uint256 randomNumber = uint256(keccak256(
            abi.encode(
                block.timestamp,
                gasleft(),
                _config[0].rndBase
            )
        ));

        //accept flows
        _config[0].rndBase = randomNumber;

        return randomNumber;
    }

    function _transfer20FromOutToPlanet(
        bytes32 category,
        address token,
        address from,
        GenericSafetyClusterType.PlanetInfo storage toPlanetInfo,
        uint256 amount
    ) internal returns (uint256 balanceTransferred){

        if (token != address(0)) {
            //from 'trusted' contract to planet
            uint256 balanceBefore = IERC20(token).balanceOf(toPlanetInfo.planetAddress);

            IERC20(token).safeTransferFrom(from, toPlanetInfo.planetAddress, amount);

            uint256 balanceAfter = IERC20(token).balanceOf(toPlanetInfo.planetAddress);
            require(balanceBefore <= balanceAfter, "_transfer20FromOutToPlanet, balance transferred into gets less");

            balanceTransferred = balanceAfter - balanceBefore;

        } else {
            //from 'trusted' contract to this cluster, then from this cluster to planet
            require(msg.value == amount, "_transfer20FromOutToPlanet, value amount mismatch");

            Address.sendValue(payable(toPlanetInfo.planetAddress), amount);

            balanceTransferred = msg.value;
        }


        _planetErc20Balance[toPlanetInfo.planetIndex][token] += balanceTransferred;
        _categoryErc20Balance[category][token] += balanceTransferred;

    }

    function _transfer20FromPlanetToOut(
        bytes32 category,
        address token,
        GenericSafetyClusterType.PlanetInfo storage fromPlanetInfo,
        address to,
        uint256 amount
    ) internal {

        require(amount <= _planetErc20Balance[fromPlanetInfo.planetIndex][token], "_transfer20FromPlanetToOut, insufficient token balance for planet");
        _planetErc20Balance[fromPlanetInfo.planetIndex][token] -= amount;
        require(amount <= _categoryErc20Balance[category][token], "_transfer20FromPlanetToOut, insufficient token balance for category");
        _categoryErc20Balance[category][token] -= amount;

        GenericSafetyPlanetInterface(fromPlanetInfo.planetAddress).takeErc20(token, to, amount);
    }

    function _transfer721FromOutToPlanet(
        bytes32 category,
        address token,
        address from,
        GenericSafetyClusterType.PlanetInfo storage toPlanetInfo,
        uint256[] memory nftIds
    ) internal {

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            IERC721(token).safeTransferFrom(from, toPlanetInfo.planetAddress, nftId);

            require(_planetErc721Balance[toPlanetInfo.planetIndex][token].add(nftId), "_transfer721FromOutToPlanet fails, nft id record mismatchs");
            _planetErc721NftTracker[token][nftId] = toPlanetInfo.planetIndex;

        }

        _categoryErc721Balance[category][token] += nftIds.length;
    }

    function _transfer721FromPlanetToOut(
        bytes32 category,
        address token,
        address to,
        uint256[] memory nftIds
    ) internal {

        require(nftIds.length <= _categoryErc721Balance[category][token], "_transfer721FromPlanetToOut, category nft balance is not enough");

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            uint256 planetIndex = _planetErc721NftTracker[token][nftId];
            GenericSafetyClusterType.PlanetInfo storage fromPlanetInfo = _planetInfo[planetIndex];

            _planetErc721NftTracker[token][nftId] = 0;
            require(_planetErc721Balance[fromPlanetInfo.planetIndex][token].remove(nftId), "_transfer721FromPlanetToOut fails, nft id record mismatchs");

            IERC721(token).safeTransferFrom(fromPlanetInfo.planetAddress, to, nftId);

        }

        _categoryErc721Balance[category][token] -= nftIds.length;
    }

    function _transfer1155FromOutToPlanet(
        bytes32 category,
        address token,
        address from,
        GenericSafetyClusterType.PlanetInfo storage toPlanetInfo,
        uint256 id,
        uint256 amount
    ) internal {

        IERC1155(token).safeTransferFrom(from, toPlanetInfo.planetAddress, id, amount, "");

        _planetErc1155Balance[toPlanetInfo.planetIndex][token][id] += amount;

        _categoryErc1155Balance[category][token][id] += amount;
    }

    function _transfer1155FromPlanetToOut(
        bytes32 category,
        address token,
        GenericSafetyClusterType.PlanetInfo storage fromPlanetInfo,
        address to,
        uint256 id,
        uint256 amount
    ) internal {

        require(amount <= _planetErc1155Balance[fromPlanetInfo.planetIndex][token][id], "_transfer1155FromPlanetToOut, insufficient token balance for planet");
        _planetErc1155Balance[fromPlanetInfo.planetIndex][token][id] -= amount;
        require(amount <= _categoryErc1155Balance[category][token][id], "_transfer1155FromPlanetToOut, insufficient token balance for category");
        _categoryErc1155Balance[category][token][id] -= amount;

        GenericSafetyPlanetInterface(fromPlanetInfo.planetAddress).takeErc1155(token, to, id, amount);
    }

    function _appendBill(
        bytes32 category,
        address token,
        bool isIn,
        address who,
        bytes32 tokenType,
        uint256 amount,
        uint256 id,
        uint256[] memory nftIds
    ) internal {
        _config[0].billIndex += 1;
        _bill[_config[0].billIndex] = GenericSafetyClusterType.Bill(category, token, isIn, who, tokenType, amount, id, nftIds);
    }

    function birth(uint256 planetCount) external onlyOwner {
        require(0 < planetCount, "planetCount is 0");
        GenericSafetyClusterType.Config storage config = _config[0];

        config.planetCount += planetCount;

        uint256 planetIndex = config.planetIndex;
        for (uint256 i = 1; i <= planetCount; i++) {
            //starts from 1
            planetIndex += 1;
            _activePlanetIndex.add(planetIndex);

            GenericSafetyClusterType.PlanetInfo storage planetInfo = _planetInfo[planetIndex];
            planetInfo.status = GenericSafetyClusterType.PLANET_STATUS_UNDEPLOYED;
        }
        config.planetIndex = planetIndex;


    }

    function nova() external onlyOwner {

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(false);

        while (true) {

            (GenericSafetyClusterType.PlanetInfo storage planetInfo,bool success) = _next(iter, false, true);
            if (!success) {
                break;
            }
            require(planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_NORMAL, "nova, planet is not born");
            require(planetInfo.planetAddress != address(0), "nova, planet is born to the dust");

        }
    }

    function getConfig() external view returns (GenericSafetyClusterType.Config memory){
        return _config[0];
    }

    function getBill(uint256 start, uint256 maxNumber) external view returns (GenericSafetyClusterType.Bill[] memory ret, bool hasMore){

        GenericSafetyClusterType.Config memory config = _config[0];

        uint256 end = Math.min(config.billIndex + 1, start + maxNumber);

        ret = new GenericSafetyClusterType.Bill[](end - start);

        uint256 index = 0;
        for (uint256 i = start; i < end; i++) {
            ret[index] = _bill[i];
            index++;
        }

        if (start + maxNumber < config.billIndex + 1) {
            hasMore = true;
        } else {
            hasMore = false;
        }
    }

    function getInteractedTokens() external view returns (address[] memory erc20tokens, address[] memory erc721tokens, address[] memory erc1155tokens){
        return (
            _interactedErc20Tokens.values(),
            _interactedErc721Tokens.values(),
            _interactedErc1155Tokens.values()
        );
    }

    function getInteractedCategory() external view returns (bytes32[] memory){
        return _interactedCategory.values();
    }

    //call this static
    function getErc20Balance(bytes32 category, address tokenAddress) external returns (
        uint256 categoryBalance,
        uint256 planetReportBalance,
        uint256 planetActualBalance
    ){

        categoryBalance = _categoryErc20Balance[category][tokenAddress];
        planetReportBalance = 0;
        planetActualBalance = 0;

        GenericSafetyClusterType.PlanetIterator memory iter = _planetIterator(false);

        while (true) {

            (GenericSafetyClusterType.PlanetInfo storage planetInfo,bool success) = _next(iter, false, false);
            if (!success) {
                break;
            }

            if (planetInfo.status == GenericSafetyClusterType.PLANET_STATUS_UNDEPLOYED) {
                require(
                    _planetErc20Balance[planetInfo.planetIndex][tokenAddress] == 0,
                    "getErc20Balance, undeployed planet should have not balance records"
                );
                continue;
            }

            planetReportBalance += _planetErc20Balance[planetInfo.planetIndex][tokenAddress];

            planetActualBalance += IERC721(tokenAddress).balanceOf(planetInfo.planetAddress);
        }
    }
}
