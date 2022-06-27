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

abstract contract StreamInstantReleaseExtension is
    Initializable,
    OwnableUpgradeable,
    ERC721MultiTokenDistributor
{
    /* INTERNAL */

    function __StreamInstantReleaseExtension_init() internal onlyInitializing {
        __Context_init();
        __StreamInstantReleaseExtension_init_unchained();
    }

    function __StreamInstantReleaseExtension_init_unchained()
        internal
        onlyInitializing
    {}

    /* INTERNAL */

    function _totalReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal pure override returns (uint256) {
        ticketTokenId_;
        claimToken_;

        return streamTotalSupply_;
    }
}
