// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721AutoIdMinterExtension.sol";

interface ERC721LockableExtensionInterface {
    function isLocked(uint256 tokenId) external view returns (bool);
}

/**
 * @dev Extension to allow locking NFTs, for use-cases like staking, without leaving holders wallet.
 */
abstract contract ERC721LockableExtension is
    ERC165Storage,
    ReentrancyGuard,
    ERC721AutoIdMinterExtension,
    ERC721LockableExtensionInterface
{
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap internal lockedTokens;

    constructor() {
        _registerInterface(type(ERC721LockableExtensionInterface).interfaceId);
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721AutoIdMinterExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * At this moment staking is only possible from a certain address (usually a smart contract).
     *
     * This is because in almost all cases you want another contract to perform custom logic on lock and unlock operations,
     * without allowing users to directly unlock their tokens and sell them, for example.
     */
    function _lock(uint256 tokenId) internal virtual {
        require(!lockedTokens.get(tokenId), "ERC721/ALREADY_LOCKED");
        lockedTokens.set(tokenId);
    }

    function _unlock(uint256 tokenId) internal virtual {
        require(lockedTokens.get(tokenId), "ERC721/NOT_LOCKED");
        lockedTokens.unset(tokenId);
    }

    /**
     * Returns if a token is locked or not.
     */
    function isLocked(uint256 tokenId) public view virtual returns (bool) {
        return lockedTokens.get(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        require(!lockedTokens.get(tokenId), "STAKABLE_ERC721/TOKEN_STAKED");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
