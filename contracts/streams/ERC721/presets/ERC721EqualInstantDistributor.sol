// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../extensions/StreamInstantReleaseExtension.sol";
import "../extensions/StreamEqualSplitExtension.sol";

contract ERC721EqualInstantDistributor is
    Initializable,
    OwnableUpgradeable,
    StreamInstantReleaseExtension,
    StreamEqualSplitExtension
{
    string public constant name = "ERC721 Equal Instant Distributor";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Equal split extension
        uint256 totalTickets;
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
        __StreamEqualSplitExtension_init(config.totalTickets);
    }
}
