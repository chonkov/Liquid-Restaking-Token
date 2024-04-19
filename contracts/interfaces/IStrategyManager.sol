// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IStrategy} from "./IStrategy.sol";
import {IDelegationManager} from "./IDelegationManager.sol";

interface IStrategyManager {
    function depositIntoStrategy(IStrategy strategy, IERC20 token, uint256 amount) external returns (uint256 shares);

    function stakerStrategyShares(address user, IStrategy strategy) external view returns (uint256 shares);

    function getDeposits(address staker) external view returns (IStrategy[] memory, uint256[] memory);

    function stakerStrategyListLength(address staker) external view returns (uint256);

    function delegation() external view returns (IDelegationManager);
}
