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

abstract contract StreamEmissionReleaseExtension is
    Initializable,
    OwnableUpgradeable,
    ERC721MultiTokenDistributor
{
    // Number of tokens released every `emissionTimeUnit`
    uint256 public emissionRate;

    // Time unit to release tokens, users can only claim once every `emissionTimeUnit`
    uint64 public emissionTimeUnit;

    // When emission and calculating tokens starts
    uint64 public emissionStart;

    // When to stop calculating the tokens released
    uint64 public emissionEnd;

    /* INIT */

    function __StreamEmissionReleaseExtension_init(
        uint256 _emissionRate,
        uint64 _emissionTimeUnit,
        uint64 _emissionStart,
        uint64 _emissionEnd
    ) internal onlyInitializing {
        __Context_init();
        __StreamEmissionReleaseExtension_init_unchained(
            _emissionRate,
            _emissionTimeUnit,
            _emissionStart,
            _emissionEnd
        );
    }

    function __StreamEmissionReleaseExtension_init_unchained(
        uint256 _emissionRate,
        uint64 _emissionTimeUnit,
        uint64 _emissionStart,
        uint64 _emissionEnd
    ) internal onlyInitializing {
        emissionRate = _emissionRate;
        emissionTimeUnit = _emissionTimeUnit;
        emissionStart = _emissionStart;
        emissionEnd = _emissionEnd;
    }

    /* ADMIN */

    function setEmissionRate(uint256 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        emissionRate = newValue;
    }

    function setEmissionTimeUnit(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        emissionTimeUnit = newValue;
    }

    function setEmissionStart(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        emissionStart = newValue;
    }

    function setEmissionEnd(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        emissionEnd = newValue;
    }

    /* PUBLIC */

    function releasedAmountUntil(uint256 calcUntil)
        public
        view
        returns (uint256)
    {
        return
            emissionRate *
            // Intentionally rounded down:
            ((calcUntil - emissionStart) / emissionTimeUnit);
    }

    function emissionAmountUntil(uint256 calcUntil)
        public
        view
        returns (uint256)
    {
        return ((calcUntil - emissionStart) * emissionRate) / emissionTimeUnit;
    }

    /* INTERNAL */

    function _totalReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view override returns (uint256) {
        streamTotalSupply_;
        ticketTokenId_;
        claimToken_;

        if (block.timestamp < emissionStart) {
            return 0;
        } else if (block.timestamp > emissionEnd) {
            return releasedAmountUntil(emissionEnd);
        } else {
            return releasedAmountUntil(block.timestamp);
        }
    }

    function _beforeClaim(uint256 ticketTokenId, address claimToken)
        internal
        view
        virtual
        override
    {
        require(emissionStart < block.timestamp, "DISTRIBUTOR/NOT_STARTED");

        require(
            entitlements[ticketTokenId][claimToken].lastClaimedAt <
                block.timestamp - emissionTimeUnit,
            "DISTRIBUTOR/TOO_EARLY"
        );
    }
}
