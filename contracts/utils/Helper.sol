// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISafeProxy, Enum} from "../interfaces/ISafeProxy.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IDelegationManager} from "../interfaces/IDelegationManager.sol";
import {LiquidRestakingManager} from "../LiquidRestakingManager.sol";

/**
 * @author Georgi Chonkov
 * @notice Helper contract used in the scripts for retrieving `calldata`
 */
contract Helper {
    /**
     * @notice Returns encoded data for `setup` function in `Safe` contract
     * @param owners_ The owners of the multi-signature walelt
     * @param threshold_ The amount of owners required for a successful execution of a transaction
     * @return The encoded data
     */
    function initCalldata(address[] calldata owners_, uint256 threshold_) external pure returns (bytes memory) {
        return abi.encodeCall(
            ISafeProxy.setup, (owners_, threshold_, address(0), "", address(0), address(0), 0, payable(address(0)))
        );
    }

    /**
     * @notice Returns encoded data for `delegateTo` function in `LiquidRestakingManager` contract
     * @param operator_ The registered operator, the manager will delegate to
     * @return The encoded data
     */
    function delegateToData(address operator_) public pure returns (bytes memory) {
        IDelegationManager.SignatureWithExpiry memory approverSignatureAndExpiry;
        bytes32 approverSalt;
        return abi.encodeCall(LiquidRestakingManager.delegateTo, (operator_, approverSignatureAndExpiry, approverSalt));
    }

    /**
     * @notice Returns encoded data for `queueWithdrawals` function in `LiquidRestakingManager` contract
     * @param strategies The strategies/strategy that will be queued for withdrawals
     * @param shares The shares burnt for each strategy
     * @param withdrawers Individual withdrawer for a specific withdrawal
     * @return The encoded data
     */
    function queueWithdrawalData(
        IStrategy[][] calldata strategies,
        uint256[][] calldata shares,
        address[] calldata withdrawers
    ) public pure returns (bytes memory) {
        IDelegationManager.QueuedWithdrawalParams[] memory queuedWithdrawalParams =
            new IDelegationManager.QueuedWithdrawalParams[](withdrawers.length);

        for (uint256 i = 0; i < withdrawers.length; i++) {
            queuedWithdrawalParams[i].strategies = strategies[i];
            queuedWithdrawalParams[i].shares = shares[i];
            queuedWithdrawalParams[i].withdrawer = withdrawers[i];
        }

        return abi.encodeCall(LiquidRestakingManager.queueWithdrawals, (queuedWithdrawalParams));
    }

    /**
     * @notice Similar to `delegateToData`, but this encodes the whole data that can be signed by an owner of the 'Safe'
     * and then submitted to 'execTransaction'. I.e. it encodes the data that can be signed by an onwer, this data consists not only
     * of the 'sub-data' to be executed by the multi-sig, but also 'authorizing' the auction itself.
     */
    function getDelegateToCalldata(address to_, address operator_, uint256 nonce_) public pure returns (bytes memory) {
        return abi.encodeCall(
            ISafeProxy.getTransactionHash,
            (to_, 0, delegateToData(operator_), Enum.Operation(0), 0, 0, 0, address(0), address(0), nonce_)
        );
    }

    /**
     * @notice Similar to `queueWithdrawalData`, but this encodes the whole data that can be signed by an owner of the 'Safe'
     * and then submitted to 'execTransaction'. I.e. it encodes the data that can be signed by an onwer, this data consists not only
     * of the 'sub-data' to be executed by the multi-sig, but also 'authorizing' the auction itself.
     */
    function getQueueWithdrawalCalldata(
        address to_,
        IStrategy[][] calldata strategies_,
        uint256[][] calldata shares_,
        address[] calldata withdrawers_,
        uint256 nonce_
    ) public pure returns (bytes memory) {
        return abi.encodeCall(
            ISafeProxy.getTransactionHash,
            (
                to_,
                0,
                queueWithdrawalData(strategies_, shares_, withdrawers_),
                Enum.Operation(0),
                0,
                0,
                0,
                address(0),
                address(0),
                nonce_
            )
        );
    }

    /**
     * @notice Returns encoded data for `completeQueuedWithdrawal` function in `LiquidRestakingManager` contract
     * @param withdrawal The withdrawal to be completed
     * @param tokens The tokens (LSTs) to receive for the particular withdrawal, if 'receiveAsTokens' is set to true
     * @param middlewareTimesIndex Index for the slasher that is not currently active
     * @param receiveAsTokens Whether to receive back shares or LSTs
     * @return The encoded data
     */
    function completeQueuedWithdrawalData(
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) public pure returns (bytes memory) {
        return abi.encodeCall(
            LiquidRestakingManager.completeQueuedWithdrawal, (withdrawal, tokens, middlewareTimesIndex, receiveAsTokens)
        );
    }

    /**
     * @notice Similar to `completeQueuedWithdrawalData`, but this encodes the whole data that can be signed by an owner of the 'Safe'
     * and then submitted to 'execTransaction'. I.e. it encodes the data that can be signed by an onwer, this data consists not only
     * of the 'sub-data' to be executed by the multi-sig, but also 'authorizing' the auction itself.
     */
    function getCompleteQueuedWithdrawalCalldata(
        address to_,
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens,
        uint256 nonce_
    ) public pure returns (bytes memory) {
        return abi.encodeCall(
            ISafeProxy.getTransactionHash,
            (
                to_,
                0,
                completeQueuedWithdrawalData(withdrawal, tokens, middlewareTimesIndex, receiveAsTokens),
                Enum.Operation(0),
                0,
                0,
                0,
                address(0),
                address(0),
                nonce_
            )
        );
    }

    /**
     * @notice Raw calldata for 'execTransaction' inside 'Safe'. This is the data when an owner wants to execute 'execTransaction' and
     * 'delegateTo' an operator. @notice Certain amount of signatures are required, by the owners of the wallet to execute the transaction
     */
    function executeDelegateToTx(address to_, address operator_, bytes calldata signature1_, bytes calldata signature2_)
        public
        pure
        returns (bytes memory)
    {
        bytes memory encodedSignatures = abi.encodePacked(signature1_, signature2_);

        return abi.encodeCall(
            ISafeProxy.execTransaction,
            (
                to_,
                0,
                delegateToData(operator_),
                Enum.Operation(0),
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                encodedSignatures
            )
        );
    }

    /**
     * @notice Raw calldata for 'execTransaction' inside 'Safe'. This is the data when an owner wants to execute 'execTransaction' and
     * 'completeQueuedWithdrawal'. @notice Certain amount of signatures are required, by the owners of the wallet to execute the transaction
     */
    function executeCompleteQueuedWithdrawalsTx(
        address to_,
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens,
        bytes calldata signature1_,
        bytes calldata signature2_
    ) public pure returns (bytes memory) {
        bytes memory encodedSignatures = abi.encodePacked(signature1_, signature2_);

        return abi.encodeCall(
            ISafeProxy.execTransaction,
            (
                to_,
                0,
                completeQueuedWithdrawalData(withdrawal, tokens, middlewareTimesIndex, receiveAsTokens),
                Enum.Operation(0),
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                encodedSignatures
            )
        );
    }

    /**
     * @notice Raw calldata for 'execTransaction' inside 'Safe'. This is the data when an owner wants to execute 'execTransaction' and
     * 'queueWithdrawals'. @notice Certain amount of signatures are required, by the owners of the wallet to execute the transaction
     */
    function executeQueueWithdrawalsTx(
        address to_,
        IStrategy[][] calldata strategies_,
        uint256[][] calldata shares_,
        address[] calldata withdrawers_,
        bytes calldata signature1_,
        bytes calldata signature2_
    ) public pure returns (bytes memory) {
        bytes memory encodedSignatures = abi.encodePacked(signature1_, signature2_);

        return abi.encodeCall(
            ISafeProxy.execTransaction,
            (
                to_,
                0,
                queueWithdrawalData(strategies_, shares_, withdrawers_),
                Enum.Operation(0),
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                encodedSignatures
            )
        );
    }

    function blockNumber() external view returns (uint256) {
        return block.number;
    }
}
