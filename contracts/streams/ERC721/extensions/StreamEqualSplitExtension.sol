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

interface IStreamEqualSplitExtension {
    function hasStreamEqualSplitExtension() external view returns (bool);
}

abstract contract StreamEqualSplitExtension is
    IStreamEqualSplitExtension,
    Initializable,
    OwnableUpgradeable,
    ERC721MultiTokenDistributor
{
    // Total number of ERC721 tokens to calculate their equal split share
    uint256 public totalTickets;

    /* INTERNAL */

    function __StreamEqualSplitExtension_init(uint256 _totalTickets)
        internal
        onlyInitializing
    {
        __Context_init();
        __StreamEqualSplitExtension_init_unchained(_totalTickets);
    }

    function __StreamEqualSplitExtension_init_unchained(uint256 _totalTickets)
        internal
        onlyInitializing
    {
        totalTickets = _totalTickets;
    }

    /* ADMIN */

    function setTotalTickets(uint256 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CANNOT_REWIND"
        );
        totalTickets = newValue;
    }

    /* PUBLIC */

    function hasStreamEqualSplitExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _totalTokenShare(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view override returns (uint256) {
        ticketTokenId_;
        claimToken_;

        return totalReleasedAmount_ / totalTickets;
    }
}
