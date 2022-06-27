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

interface IStreamVestingReleaseExtension {
    function hasStreamVestingReleaseExtension() external view returns (bool);
}

abstract contract StreamVestingReleaseExtension is
    IStreamVestingReleaseExtension,
    Initializable,
    OwnableUpgradeable,
    ERC721MultiTokenDistributor
{
    // Start of the vesting schedule
    uint64 public vestingStartTimestamp;

    // Duration of the vesting schedule
    uint64 public vestingDurationSeconds;

    /* INTERNAL */

    function __StreamVestingReleaseExtension_init(
        uint64 _vestingStartTimestamp,
        uint64 _vestingDurationSeconds
    ) internal onlyInitializing {
        __Context_init();
        __StreamVestingReleaseExtension_init_unchained(
            _vestingStartTimestamp,
            _vestingDurationSeconds
        );
    }

    function __StreamVestingReleaseExtension_init_unchained(
        uint64 _vestingStartTimestamp,
        uint64 _vestingDurationSeconds
    ) internal onlyInitializing {
        vestingStartTimestamp = _vestingStartTimestamp;
        vestingDurationSeconds = _vestingDurationSeconds;
    }

    /* ADMIN */

    function setVestingStartTimestamp(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        vestingStartTimestamp = newValue;
    }

    function setVestingDurationSeconds(uint64 newValue) public onlyOwner {
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );
        vestingDurationSeconds = newValue;
    }

    /* PUBLIC */

    function hasStreamVestingReleaseExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _totalReleasedAmount(
        uint256 _streamTotalSupply,
        uint256 _ticketTokenId,
        address _claimToken
    ) internal view override returns (uint256) {
        _ticketTokenId;
        _claimToken;

        if (block.timestamp < vestingStartTimestamp) {
            return 0;
        } else if (
            block.timestamp > vestingStartTimestamp + vestingDurationSeconds
        ) {
            return _streamTotalSupply;
        } else {
            return
                (_streamTotalSupply *
                    (block.timestamp - vestingStartTimestamp)) /
                vestingDurationSeconds;
        }
    }
}
