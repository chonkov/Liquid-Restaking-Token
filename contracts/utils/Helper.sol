// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ISafeProxy, Enum} from "../interfaces/ISafeProxy.sol";
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
    function returnData(address[] calldata owners_, uint256 threshold_) external pure returns (bytes memory) {
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
     * @notice Returns `keccak256` of the encoded struct populated with data about the next execution call
     * @param to_ The contract a call will be made to
     * @param operator_ The operator to delegate to
     * @param nonce_ A random number required by `Safe` for non-replay attacks
     * @return The transcation hash
     */
    function getTransactionHash(address to_, address operator_, uint256 nonce_) public pure returns (bytes32) {
        return keccak256(
            abi.encodeCall(
                ISafeProxy.getTransactionHash,
                (to_, 0, delegateToData(operator_), Enum.Operation(0), 0, 0, 0, address(0), address(0), nonce_)
            )
        );
    }

    /**
     * @notice Returns encoded data for the `execTransaction` function
     * @param to_ The contract a call will be made to
     * @param operator_ The operator to delegate to
     * @param signature1_ First signature
     * @param signature2_ Second signature
     * @return The encoded data
     */
    function executeTx(address to_, address operator_, bytes calldata signature1_, bytes calldata signature2_)
        public
        pure
        returns (bytes memory)
    {
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
                abi.encode(signature1_, signature2_)
            )
        );
    }
}
