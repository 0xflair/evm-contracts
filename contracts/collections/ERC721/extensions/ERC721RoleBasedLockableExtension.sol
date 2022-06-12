// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721LockableExtension.sol";

interface ERC721RoleBasedLockableExtensionInterface {
    function hasRoleBasedLockableExtension() external view returns (bool);
}

/**
 * @dev Extension to allow locking NFTs, for use-cases like staking, without leaving holders wallet, using roles.
 */
abstract contract ERC721RoleBasedLockableExtension is
    ERC721LockableExtension,
    AccessControl,
    ERC721RoleBasedLockableExtensionInterface
{
    using BitMaps for BitMaps.BitMap;

    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");

    constructor() {
        _registerInterface(
            type(ERC721RoleBasedLockableExtensionInterface).interfaceId
        );
    }

    // ADMIN

    /**
     * Locks token(s) to effectively lock them, while keeping in the same wallet.
     * This mechanism prevents them from being transferred, yet still will show correct owner.
     */
    function lock(uint256[] calldata tokenIds) public virtual nonReentrant {
        require(
            hasRole(STAKER_ROLE, msg.sender),
            "STAKABLE_ERC721/NOT_STAKER_ROLE"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lock(tokenIds[i]);
        }
    }

    /**
     * Unlocks locked token(s) to be able to transfer.
     */
    function unlock(uint256[] calldata tokenIds) public virtual nonReentrant {
        require(
            hasRole(STAKER_ROLE, msg.sender),
            "STAKABLE_ERC721/NOT_STAKER_ROLE"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unlock(tokenIds[i]);
        }
    }

    // PUBLIC

    function hasRoleBasedLockableExtension()
        public
        view
        virtual
        returns (bool)
    {
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721LockableExtension, AccessControl)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}
