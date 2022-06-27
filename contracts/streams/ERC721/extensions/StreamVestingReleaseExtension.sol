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

abstract contract StreamVestingReleaseExtension is
    Initializable,
    OwnableUpgradeable,
    ERC721MultiTokenDistributor
{
    // Start of the vesting schedule
    uint64 public startTimestamp;

    // Duration of the vesting schedule
    uint64 public durationSeconds;

    /* INTERNAL */

    function __StreamVestingReleaseExtension_init(
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) internal onlyInitializing {
        __Context_init();
        __StreamVestingReleaseExtension_init_unchained(
            _startTimestamp,
            _durationSeconds
        );
    }

    function __StreamVestingReleaseExtension_init_unchained(
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) internal onlyInitializing {
        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
    }

    /* ADMIN */

    function setStartTimestamp(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        startTimestamp = newValue;
    }

    function setDurationSeconds(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        durationSeconds = newValue;
    }

    /* PUBLIC */

    function _totalReleasedAmount(
        uint256 _streamTotalSupply,
        uint256 _ticketTokenId,
        address _claimToken
    ) internal view override returns (uint256) {
        _ticketTokenId;
        _claimToken;

        if (block.timestamp < startTimestamp) {
            return 0;
        } else if (block.timestamp > startTimestamp + durationSeconds) {
            return _streamTotalSupply;
        } else {
            return
                (_streamTotalSupply * (block.timestamp - startTimestamp)) /
                durationSeconds;
        }
    }
}
