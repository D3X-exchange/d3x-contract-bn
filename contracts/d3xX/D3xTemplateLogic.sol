// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./D3xTemplateLayout.sol";
import "../dependant/ownable/OwnableLogic.sol";
import "../nameServiceRef/NameServiceRefLogic.sol";
import "./D3xTemplateInterface.sol";

import "./D3xTemplateType.sol";

contract D3xTemplateLogic is Delegate, D3xTemplateLayout,
OwnableLogic,
NameServiceRefLogic,
D3xTemplateInterface
{

    using SafeERC20 for IERC20;

}
