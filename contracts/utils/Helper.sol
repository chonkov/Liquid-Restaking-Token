// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ISafeProxy, Enum} from "../interfaces/ISafeProxy.sol";
import {IDelegationManager} from "../interfaces/IDelegationManager.sol";
import {LiquidRestakingManager} from "../LiquidRestakingManager.sol";

contract Helper {
    function returnData(address[] calldata owners_, uint256 threshold_) external pure returns (bytes memory) {
        return abi.encodeCall(
            ISafeProxy.setup, (owners_, threshold_, address(0), "", address(0), address(0), 0, payable(address(0)))
        );
    }

    function delegateToData(address operator_) public pure returns (bytes memory) {
        IDelegationManager.SignatureWithExpiry memory approverSignatureAndExpiry;
        bytes32 approverSalt;
        return abi.encodeCall(LiquidRestakingManager.delegateTo, (operator_, approverSignatureAndExpiry, approverSalt));
    }

    function getTransactionHash(address to_, address operator_, uint256 nonce_) public pure returns (bytes32) {
        return keccak256(
            abi.encodeCall(
                ISafeProxy.getTransactionHash,
                (to_, 0, delegateToData(operator_), Enum.Operation(0), 0, 0, 0, address(0), address(0), nonce_)
            )
        );
    }

    function executeTx(address to_, address operator_, bytes calldata signature1, bytes calldata signature2)
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
                abi.encode(signature1, signature2)
            )
        );
    }
}
