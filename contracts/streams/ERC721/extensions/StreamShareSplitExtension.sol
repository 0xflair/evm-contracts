// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenDistributor.sol";

interface IStreamShareSplitExtension {
    function hasStreamShareSplitExtension() external view returns (bool);
}

abstract contract StreamShareSplitExtension is
    IStreamShareSplitExtension,
    Initializable,
    OwnableUpgradeable,
    ERC721MultiTokenDistributor
{
    event SharesUpdated(uint256 tokenId, uint256 prevShares, uint256 newShares);

    // Sum of all the share units ever configured
    uint256 public totalShares;

    // Map of ticket token ID -> share of the stream
    mapping(uint256 => uint256) public shares;

    /* INTERNAL */

    function __StreamShareSplitExtension_init(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) internal onlyInitializing {
        __Context_init();
        __StreamShareSplitExtension_init_unchained(_tokenIds, _shares);
    }

    function __StreamShareSplitExtension_init_unchained(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) internal onlyInitializing {
        setSharesForTokens(_tokenIds, _shares);
    }

    function setSharesForTokens(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) public onlyOwner {
        require(
            _shares.length == _tokenIds.length,
            "DISTRIBUTOR/ARGS_MISMATCH"
        );
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );

        for (uint256 i = 0; i < _shares.length; i++) {
            _updateShares(_tokenIds[i], _shares[i]);
        }
    }

    /* PUBLIC */

    function hasStreamShareSplitExtension() external pure returns (bool) {
        return true;
    }

    function getSharesByTokens(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _shares = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _shares.length; i++) {
            _shares[i] = shares[_tokenIds[i]];
        }

        return _shares;
    }

    function _totalTokenShare(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view override returns (uint256) {
        claimToken_;

        return (totalReleasedAmount_ * shares[ticketTokenId_]) / totalShares;
    }

    /* INTERNAL */

    function _updateShares(uint256 tokenId, uint256 newShares) private {
        uint256 prevShares = shares[tokenId];

        shares[tokenId] = newShares;
        totalShares = totalShares + newShares - prevShares;

        require(totalShares >= 0, "DISTRIBUTOR/NEGATIVE_SHARES");

        emit SharesUpdated(tokenId, prevShares, newShares);
    }
}
