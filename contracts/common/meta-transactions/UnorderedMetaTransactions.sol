// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract UnorderedMetaTransactions is
    Context,
    EIP712,
    ReentrancyGuard
{
    using Math for uint256;
    using ECDSA for bytes32;

    /// @dev Describes an unordered meta transaction.
    struct UnorderedMetaTransaction {
        // Signer of meta-transaction. On whose behalf to execute the MTX.
        address payable signer;
        // Amount of ETH to attach to the call.
        uint256 value;
        // Minimum gas price.
        uint256 minGasPrice;
        // Maximum gas price.
        uint256 maxGasPrice;
        // MTX is invalid after this time.
        uint256 expiresAt;
        // Nonce to make this MTX unique.
        uint256 salt;
        // Encoded call data to a function on this contract.
        bytes callData;
    }

    /// @dev Describes the state of a meta transaction.
    struct ExecuteState {
        // Hash of the meta-transaction data.
        bytes32 hash;
        // The meta-transaction data.
        UnorderedMetaTransaction mtx;
        // The meta-transaction signature (by `mtx.signer`).
        bytes signature;
    }

    /// @dev Emitted whenever a meta-transaction is executed.
    /// @param hash The meta-transaction hash.
    /// @param signer Who to execute the meta-transaction on behalf of.
    /// @param sender Who executed the meta-transaction.
    event MetaTransactionExecuted(bytes32 hash, address signer, address sender);

    bytes32 public immutable UMTX_EIP712_TYPEHASH =
        keccak256(
            "UnorderedMetaTransaction("
            "address signer,"
            "uint256 value,"
            "uint256 minGasPrice,"
            "uint256 maxGasPrice,"
            "uint256 expiresAt,"
            "uint256 salt,"
            "bytes callData"
            ")"
        );

    mapping(bytes32 => uint256) mtxHashToExecutedBlockNumber;

    /// @dev Refunds up to `msg.value` leftover ETH at the end of the call.
    modifier refundsAttachedEth() {
        _;
        uint256 remainingBalance = msg.value.min(address(this).balance);
        if (remainingBalance > 0) {
            payable(msg.sender).transfer(remainingBalance);
        }
    }

    /// @dev Ensures that the ETH balance of `this` does not go below the
    ///      initial ETH balance before the call (excluding ETH attached to the call).
    modifier doesNotReduceEthBalance() {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        require(initialBalance <= address(this).balance, "ETH_LEAK");
    }

    constructor() EIP712("UnorderedMetaTransactions", "v0.1") {}

    /// @dev Get the EIP712 hash of a meta-transaction.
    /// @param mtx The meta-transaction.
    /// @return mtxHash The EIP712 hash of `mtx`.
    function getMetaTransactionHash(UnorderedMetaTransaction memory mtx)
        public
        view
        returns (bytes32 mtxHash)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        UMTX_EIP712_TYPEHASH,
                        mtx.signer,
                        mtx.value,
                        mtx.minGasPrice,
                        mtx.maxGasPrice,
                        mtx.expiresAt,
                        mtx.salt,
                        keccak256(mtx.callData)
                    )
                )
            );
    }

    /// @dev Execute multiple meta-transactions.
    /// @param mtxs The meta-transactions.
    /// @param signatures The signature by each respective `mtx.signer`.
    /// @return returnResults The ABI-encoded results of the underlying calls.
    function batchExecuteMetaTransactions(
        UnorderedMetaTransaction[] memory mtxs,
        bytes[] memory signatures
    )
        public
        payable
        nonReentrant
        doesNotReduceEthBalance
        refundsAttachedEth
        returns (bytes[] memory returnResults)
    {
        require(mtxs.length == signatures.length, "INVALID_SIGNATURES");

        returnResults = new bytes[](mtxs.length);
        for (uint256 i = 0; i < mtxs.length; ++i) {
            ExecuteState memory state;

            state.mtx = mtxs[i];
            state.hash = getMetaTransactionHash(mtxs[i]);
            state.signature = signatures[i];

            returnResults[i] = _executeMetaTransactionPrivate(state);
        }
    }

    /// @dev Execute a meta-transaction by `sender`. Low-level, hidden variant.
    /// @param state The `ExecuteState` for this metatransaction, with `hash`, `mtx`, and `signature` fields filled.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function _executeMetaTransactionPrivate(ExecuteState memory state)
        private
        returns (bytes memory returnResult)
    {
        _validateMetaTransaction(state);

        // Mark the transaction executed by storing the block at which it was executed.
        // Currently the block number just indicates that the mtx was executed and
        // serves no other purpose from within this contract.
        mtxHashToExecutedBlockNumber[state.hash] = block.number;

        // Execute the call
        bool success;

        // Make an arbitrary internal, meta-transaction call.
        // Warning: Do not let unadulterated `callData` into this function.
        (success, returnResult) = address(this).call{value: state.mtx.value}(
            abi.encodePacked(state.mtx.callData, state.mtx.signer)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= state.mtx.minGasPrice / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            assembly {
                invalid()
            }
        }

        require(success, "MTX_CALL_FAILED");

        emit MetaTransactionExecuted(state.hash, state.mtx.signer, msg.sender);
    }

    /// @dev Validate that a meta-transaction is executable.
    function _validateMetaTransaction(ExecuteState memory state) private view {
        // Must not be expired.
        require(state.mtx.expiresAt > block.timestamp, "MTX_EXPIRED");

        // Must have a valid gas price.
        require(
            state.mtx.minGasPrice <= tx.gasprice ||
                state.mtx.maxGasPrice >= tx.gasprice,
            "MTX_INVALID_GAS"
        );

        // Must have enough ETH.
        require(state.mtx.value <= address(this).balance, "MTX_INVALID_VALUE");

        // Must be signed by the signer.
        require(
            state.hash.recover(state.signature) == state.mtx.signer,
            "MTX_INVALID_SIGNATURE"
        );

        // Transaction must not have been already executed.
        require(mtxHashToExecutedBlockNumber[state.hash] == 0, "MTX_REPLAYED");
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (msg.data.length >= 24 && address(this) == msg.sender) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (address(this) == msg.sender) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
