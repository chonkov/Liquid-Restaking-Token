// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidRestakingToken is IERC20 {
    function mint(address account, uint256 value) external;

    function burn(address account, uint256 value) external;
}
