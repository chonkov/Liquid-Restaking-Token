// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ISignatureUtils} from "./ISignatureUtils.sol";
import {IStrategy} from "./IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDelegationManager is ISignatureUtils {
    struct Withdrawal {
        address staker;
        address delegatedTo;
        address withdrawer;
        uint256 nonce;
        uint32 startBlock;
        IStrategy[] strategies;
        uint256[] shares;
    }

    struct QueuedWithdrawalParams {
        IStrategy[] strategies;
        uint256[] shares;
        address withdrawer;
    }

    function delegateTo(address operator, SignatureWithExpiry memory approverSignatureAndExpiry, bytes32 approverSalt)
        external;

    function undelegate(address staker) external returns (bytes32[] memory withdrawalRoot);

    function queueWithdrawals(QueuedWithdrawalParams[] calldata queuedWithdrawalParams)
        external
        returns (bytes32[] memory);

    function completeQueuedWithdrawal(
        Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external;

    function completeQueuedWithdrawals(
        Withdrawal[] calldata withdrawals,
        IERC20[][] calldata tokens,
        uint256[] calldata middlewareTimesIndexes,
        bool[] calldata receiveAsTokens
    ) external;

    function delegatedTo(address staker) external view returns (address);

    function isDelegated(address staker) external view returns (bool);

    function isOperator(address operator) external view returns (bool);
}
