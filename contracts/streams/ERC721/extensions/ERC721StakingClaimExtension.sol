// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721LockableExtension} from "../../../collections/ERC721/extensions/ERC721LockableExtension.sol";

import "../base/ERC721MultiTokenStream.sol";

/**
 * @author Flair (https://flair.finance)
 */
interface IERC721StakingClaimExtension {
    function hasERC721StakingClaimExtension() external view returns (bool);

    function stake(uint256 tokenId) external;

    function stake(uint256[] calldata tokenIds) external;
}

abstract contract ERC721StakingClaimExtension is
    IERC721StakingClaimExtension,
    Initializable,
    ERC165Storage,
    Ownable,
    ERC721MultiTokenStream
{
    // Minimum seconds that token must be locked before unstaking and claiming
    uint256 public minLockTime;

    // Map of token ID to the time of staking
    mapping(uint256 => uint64) public stakingTime;

    /* INIT */

    function __ERC721StakingClaimExtension_init(uint64 _minLockTime)
        internal
        onlyInitializing
    {
        __ERC721StakingClaimExtension_init_unchained(_minLockTime);
    }

    function __ERC721StakingClaimExtension_init_unchained(uint64 _minLockTime)
        internal
        onlyInitializing
    {
        minLockTime = _minLockTime;

        _registerInterface(type(IERC721StakingClaimExtension).interfaceId);
    }

    /* ADMIN */

    function setMinLockTime(uint256 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");
        minLockTime = newValue;
    }

    /* PUBLIC */

    function hasERC721StakingClaimExtension() external pure returns (bool) {
        return true;
    }

    function stake(uint256 tokenId) public {
        require(
            _msgSender() == IERC721(ticketToken).ownerOf(tokenId),
            "STREAM/NOT_TOKEN_OWNER"
        );

        stakingTime[tokenId] = uint64(block.timestamp);

        IERC721LockableExtension(ticketToken).lock(tokenId);
    }

    function stake(uint256[] calldata tokenIds) public {
        address sender = _msgSender();
        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                sender == IERC721(ticketToken).ownerOf(tokenIds[i]),
                "STREAM/NOT_TOKEN_OWNER"
            );

            stakingTime[tokenIds[i]] = currentTime;
        }

        IERC721LockableExtension(ticketToken).lock(tokenIds);
    }

    /* INTERNAL */

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address owner_
    ) internal virtual override {
        require(_msgSender() == owner_, "STREAM/NOT_TOKEN_OWNER");
        require(stakingTime[ticketTokenId_] > 0, "STREAM/NOT_STAKED");

        super._beforeClaim(ticketTokenId_, claimToken_, owner_);

        require(
            block.timestamp > stakingTime[ticketTokenId_] &&
                block.timestamp - stakingTime[ticketTokenId_] > minLockTime,
            "STREAM/MIN_LOCKED_TIME"
        );
    }

    function _afterClaimCalculation(
        uint256 ticketTokenId_,
        address claimToken_,
        uint256 claimable_
    ) internal virtual override {
        claimToken_;
        claimable_;

        stakingTime[ticketTokenId_] = 0;
        IERC721LockableExtension(ticketToken).unlock(ticketTokenId_);
    }
}
