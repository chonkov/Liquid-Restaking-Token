// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface ILiquidRestakingManager {
    event Deposit(address indexed sender, address indexed receiver, uint256 amount);

    function deposit(uint256 amount, address receiver) external;
}
