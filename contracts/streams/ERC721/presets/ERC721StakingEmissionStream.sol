// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../../common/EmergencyOwnerWithdrawExtension.sol";
import "../extensions/ERC721EmissionReleaseExtension.sol";
import "../extensions/ERC721LockedStakingExtension.sol";
import "../extensions/ERC721LockableClaimExtension.sol";

/**
 * @author Flair (https://flair.finance)
 */
contract ERC721StakingEmissionStream is
    Initializable,
    Ownable,
    EmergencyOwnerWithdrawExtension,
    ERC721EmissionReleaseExtension,
    ERC721LockedStakingExtension,
    ERC721LockableClaimExtension
{
    using Address for address;
    using Address for address payable;

    string public constant name = "ERC721 Staking Emission Stream";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Locked staking extension
        uint64 minStakingLockTime; // in seconds. Minimum time the NFT must stay locked before unstaking.
        // Emission release extension
        uint256 emissionRate;
        uint64 emissionTimeUnit;
        uint64 emissionStart;
        uint64 emissionEnd;
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

        __EmergencyOwnerWithdrawExtension_init();
        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721LockedStakingExtension_init(config.minStakingLockTime);
        __ERC721EmissionReleaseExtension_init(
            config.emissionRate,
            config.emissionTimeUnit,
            config.emissionStart,
            config.emissionEnd
        );
        __ERC721LockableClaimExtension_init(config.claimLockedUntil);
    }

    function _totalStreamReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    )
        internal
        view
        virtual
        override(ERC721MultiTokenStream, ERC721EmissionReleaseExtension)
        returns (uint256)
    {
        // Removing the logic from emission extension because it is irrevelant when staking.
        return 0;
    }

    function _totalTokenReleasedAmount(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual override returns (uint256) {
        totalReleasedAmount_;
        ticketTokenId_;
        claimToken_;

        uint64 sumTotalOfStakingDurations = totalStakedDuration(ticketTokenId_);

        return
            emissionRate *
            // Intentionally rounded down
            (sumTotalOfStakingDurations / emissionTimeUnit);
    }

    function _stakingTimeLimit()
        internal
        view
        virtual
        override
        returns (uint64)
    {
        return emissionEnd;
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address owner_
    )
        internal
        override(
            ERC721MultiTokenStream,
            ERC721EmissionReleaseExtension,
            ERC721LockableClaimExtension
        )
    {
        ERC721LockableClaimExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            owner_
        );
        ERC721EmissionReleaseExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            owner_
        );
    }

    /* PUBLIC */

    function stake(uint256 tokenId) public override {
        require(
            uint64(block.timestamp) >= emissionStart,
            "STREAM/NOT_STARTED_YET"
        );

        super.stake(tokenId);
    }

    function stake(uint256[] calldata tokenIds) public override {
        require(
            uint64(block.timestamp) >= emissionStart,
            "STREAM/NOT_STARTED_YET"
        );

        super.stake(tokenIds);
    }
}