// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDelegationManager} from "./IDelegationManager.sol";

interface ILiquidRestakingManager {
    event Deposit(address indexed sender, address indexed receiver, uint256 amount);
    event DelegateTo(address indexed operator);
    event UndelegateFrom();
    event QueueWithdrawal(IDelegationManager.QueuedWithdrawalParams[] indexed queuedWithdrawalParams);
    event CompleteQueuedWithdrawal(
        IDelegationManager.Withdrawal indexed withdrawal,
        IERC20[] tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    );

    function deposit(uint256 amount, address receiver) external;

    function delegateTo(
        address operator,
        IDelegationManager.SignatureWithExpiry calldata approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external;

    function undelegateFrom() external;

    function queueWithdrawals(IDelegationManager.QueuedWithdrawalParams[] calldata queuedWithdrawalParams) external;

    function completeQueuedWithdrawal(
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external;
}
