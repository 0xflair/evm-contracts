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
import "../extensions/ERC721ShareSplitExtension.sol";
import "../extensions/ERC721LockableClaimExtension.sol";

contract ERC721ShareEmissionStream is
    Initializable,
    Ownable,
    EmergencyOwnerWithdrawExtension,
    ERC721EmissionReleaseExtension,
    ERC721ShareSplitExtension,
    ERC721LockableClaimExtension
{
    using Address for address;
    using Address for address payable;

    string public constant name = "ERC721 Share Emission Stream";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Emission release extension
        uint256 emissionRate;
        uint64 emissionTimeUnit;
        uint64 emissionStart;
        uint64 emissionEnd;
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

        __EmergencyOwnerWithdrawExtension_init();
        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721EmissionReleaseExtension_init(
            config.emissionRate,
            config.emissionTimeUnit,
            config.emissionStart,
            config.emissionEnd
        );
        __ERC721ShareSplitExtension_init(config.tokenIds, config.shares);
        __ERC721LockableClaimExtension_init(config.claimLockedUntil);
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address owner_
    )
        internal
        override(
            ERC721MultiTokenStream,
            ERC721LockableClaimExtension,
            ERC721EmissionReleaseExtension
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
}
