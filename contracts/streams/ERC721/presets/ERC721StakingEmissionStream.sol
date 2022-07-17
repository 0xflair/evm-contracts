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
import "../extensions/ERC721StakingClaimExtension.sol";

/**
 * @author Flair (https://flair.finance)
 */
contract ERC721StakingEmissionStream is
    Initializable,
    Ownable,
    ERC721EmissionReleaseExtension,
    ERC721StakingClaimExtension,
    EmergencyOwnerWithdrawExtension
{
    using Address for address;
    using Address for address payable;

    string public constant name = "ERC721 Staking Emission Stream";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Staking claim extension
        uint64 minLockTime;
        // Emission release extension
        uint256 emissionRate;
        uint64 emissionTimeUnit;
        uint64 emissionStart;
        uint64 emissionEnd;
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
        __ERC721StakingClaimExtension_init(config.minLockTime);
        __ERC721EmissionReleaseExtension_init(
            config.emissionRate,
            config.emissionTimeUnit,
            config.emissionStart,
            config.emissionEnd
        );
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address owner_
    )
        internal
        override(ERC721EmissionReleaseExtension, ERC721StakingClaimExtension)
    {
        return
            ERC721StakingClaimExtension._beforeClaim(
                ticketTokenId_,
                claimToken_,
                owner_
            );
    }

    function _afterClaimCalculation(
        uint256 ticketTokenId_,
        address claimToken_,
        uint256 claimable_
    )
        internal
        virtual
        override(ERC721MultiTokenStream, ERC721StakingClaimExtension)
    {
        return
            ERC721StakingClaimExtension._afterClaimCalculation(
                ticketTokenId_,
                claimToken_,
                claimable_
            );
    }

    function _totalTokenShare(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual override returns (uint256) {
        totalReleasedAmount_;
        ticketTokenId_;
        claimToken_;
        // For staking this is irrelevant, so we return 0.
        return 0;
    }

    /* PUBLIC */

    function streamClaimableAmount(uint256 ticketTokenId, address claimToken)
        public
        view
        virtual
        override
        returns (uint256)
    {
        claimToken;

        if (stakingTime[ticketTokenId] == 0) {
            return 0;
        }

        if (emissionStart > stakingTime[ticketTokenId]) {
            return 0;
        }

        uint64 currentTime = uint64(block.timestamp);
        uint256 endTime = currentTime > emissionEnd ? emissionEnd : currentTime;

        if (stakingTime[ticketTokenId] > endTime) {
            return 0;
        }

        return
            emissionRate *
            // Intentionally rounded down
            ((endTime - stakingTime[ticketTokenId]) / emissionTimeUnit);
    }

    function rewardAmountUntil(uint256 ticketTokenId, uint64 calcUntil)
        public
        view
        virtual
        returns (uint256)
    {
        if (stakingTime[ticketTokenId] == 0) {
            return 0;
        }

        if (emissionStart > stakingTime[ticketTokenId]) {
            return 0;
        }

        uint256 endTime = calcUntil > emissionEnd ? emissionEnd : calcUntil;

        if (stakingTime[ticketTokenId] > endTime) {
            return 0;
        }

        return
            ((endTime - stakingTime[ticketTokenId]) * emissionRate) /
            emissionTimeUnit;
    }
}
