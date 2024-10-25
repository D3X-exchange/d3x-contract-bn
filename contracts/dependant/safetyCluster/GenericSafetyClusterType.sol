// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GenericSafetyClusterType {

    uint256 constant PLANET_STATUS_UNKNOWN = 0;
    uint256 constant PLANET_STATUS_UNDEPLOYED = 1;
    uint256 constant PLANET_STATUS_NORMAL = 2;
    uint256 constant PLANET_STATUS_OBSOLETE = 3;

    struct Config {
        uint256 rndBase;
        uint256 planetCount;
        //starts from 1
        uint256 planetIndex;
        //starts from 1
        uint256 billIndex;
    }

    struct PlanetInfo {
        uint256 planetIndex;
        address planetAddress;
        uint256 status;
    }

    struct PlanetIterator {
        uint256 _activePlanetOffsetCursor;
        uint256 _activePlanetOffsetOriginal;
        uint256 _activePlanetOffsetLength;
    }

    struct Bill {
        bytes32 category;
        address token;
        bool isIn;
        address who;
        bytes32 tokenType;
        //for 20 and 1155,  amount for 721
        uint256 amount;
        //for 1155 and 20
        uint256 id;
        //for 721
        uint256[] nftIds;
    }
}
