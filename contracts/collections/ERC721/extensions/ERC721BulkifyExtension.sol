// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

interface ERC721BulkifyExtensionInterface {
    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external;
}

/**
 * @dev Extension to add bulk operations to a standard ERC721 contract.
 */
abstract contract ERC721BulkifyExtension is
    Initializable,
    Context,
    ERC165Storage,
    IERC721,
    ERC721BulkifyExtensionInterface
{
    function __ERC721BulkifyExtension_init() internal onlyInitializing {
        __ERC721BulkifyExtension_init_unchained();
    }

    function __ERC721BulkifyExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(ERC721BulkifyExtensionInterface).interfaceId);
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, IERC165)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * Useful for when user wants to return tokens to get a refund,
     * or when they want to transfer lots of tokens by paying gas fee only once.
     */
    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(this).transferFrom(from, _msgSender(), tokenIds[i]);
        }
    }
}
