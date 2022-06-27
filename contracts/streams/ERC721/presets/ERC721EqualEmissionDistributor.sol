// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../extensions/StreamEmissionReleaseExtension.sol";
import "../extensions/StreamEqualSplitExtension.sol";

contract ERC721EqualEmissionDistributor is
    Initializable,
    OwnableUpgradeable,
    StreamEmissionReleaseExtension,
    StreamEqualSplitExtension
{
    using Address for address;
    using Address for address payable;

    string public constant name = "ERC721 Equal Emission Distributor";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Equal split extension
        uint256 totalTickets;
        // Emission release extension
        uint256 emissionRate;
        uint64 emissionTimeUnit;
        uint64 emissionStart;
        uint64 emissionEnd;
    }

    /* INTERNAL */

    constructor(Config memory config) {
        initialize(config);
    }

    function initialize(Config memory config) public initializer {
        __Context_init();
        __Ownable_init();
        __ERC721MultiTokenDistributor_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __StreamEmissionReleaseExtension_init(
            config.emissionRate,
            config.emissionTimeUnit,
            config.emissionStart,
            config.emissionEnd
        );
        __StreamEqualSplitExtension_init(config.totalTickets);
    }

    function _beforeClaim(uint256 ticketTokenId, address claimToken)
        internal
        view
        override(ERC721MultiTokenDistributor, StreamEmissionReleaseExtension)
    {
        return
            StreamEmissionReleaseExtension._beforeClaim(
                ticketTokenId,
                claimToken
            );
    }
}
