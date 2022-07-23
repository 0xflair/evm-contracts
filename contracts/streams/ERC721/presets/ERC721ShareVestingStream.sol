// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../../common/WithdrawExtension.sol";
import "../extensions/ERC721ShareSplitExtension.sol";
import "../extensions/ERC721VestingReleaseExtension.sol";
import "../extensions/ERC721LockableClaimExtension.sol";

contract ERC721ShareVestingStream is
    Initializable,
    Ownable,
    ERC721VestingReleaseExtension,
    ERC721ShareSplitExtension,
    ERC721LockableClaimExtension,
    WithdrawExtension
{
    string public constant name = "ERC721 Share Vesting Stream";

    string public constant version = "0.1";

    struct Config {
        // Core
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Vesting release extension
        uint64 startTimestamp;
        uint64 durationSeconds;
        // Share split extension
        uint256[] tokenIds;
        uint256[] shares;
        // Lockable claim extension
        uint64 claimLockedUntil;
    }

    /* INTERNAL */

    constructor(Config memory config) {
        initialize(config, msg.sender);
    }

    function initialize(Config memory config, address deployer)
        public
        initializer
    {
        _transferOwnership(deployer);

        __WithdrawExtension_init(deployer, WithdrawMode.OWNER);
        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721VestingReleaseExtension_init(
            config.startTimestamp,
            config.durationSeconds
        );
        __ERC721ShareSplitExtension_init(config.tokenIds, config.shares);
        __ERC721LockableClaimExtension_init(config.claimLockedUntil);
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address owner_
    ) internal override(ERC721MultiTokenStream, ERC721LockableClaimExtension) {
        ERC721LockableClaimExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            owner_
        );
    }
}
