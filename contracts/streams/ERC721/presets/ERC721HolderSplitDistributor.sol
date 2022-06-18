// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../core/ERC721MultiTokenDistributor.sol";

contract ERC721HolderSplitDistributor is
    Ownable,
    Initializable,
    ERC721MultiTokenDistributor
{
    event SharesUpdated(uint256 tokenId, uint256 prevShares, uint256 newShares);

    using Address for address;
    using Address for address payable;

    string public constant name = "ERC721 Holder-split Distributor";

    string public constant version = "0.1";

    struct Config {
        address ticketToken;
        uint256[] tokenIds;
        uint256[] shares;
        uint256 lockedUntilTimestamp;
    }

    // Sum of all the share units ever configured
    uint256 public totalShares;

    // Map of ticket token ID -> share of the stream
    mapping(uint256 => uint256) public shares;

    // Locks changing the configuration until this timestamp is reached
    uint256 lockedUntilTimestamp;

    /* INTERNAL */

    constructor(Config memory config) {
        initialize(msg.sender, config);
    }

    function initialize(address owner, Config memory config)
        public
        initializer
    {
        Ownable._transferOwnership(owner);
        ERC721MultiTokenDistributor._setup(config.ticketToken);

        setShares(config.tokenIds, config.shares);
        lockedUntilTimestamp = config.lockedUntilTimestamp;
    }

    // ADMIN

    function lockUntil(uint256 newValue) public onlyOwner {
        require(newValue > lockedUntilTimestamp, "DISTRIBUTOR/CANNOT_REWIND");
        lockedUntilTimestamp = newValue;
    }

    function setShares(uint256[] memory _tokenIds, uint256[] memory _shares)
        public
        onlyOwner
    {
        require(
            _shares.length == _tokenIds.length,
            "DISTRIBUTOR/ARGS_MISMATCH"
        );
        require(
            lockedUntilTimestamp < block.timestamp,
            "DISTRIBUTOR/CONFIG_LOCKED"
        );

        for (uint256 i = 0; i < _shares.length; i++) {
            _updateShares(_tokenIds[i], _shares[i]);
        }
    }

    // PUBLIC

    function calculateClaimableAmount(uint256 ticketTokenId)
        public
        view
        returns (uint256)
    {
        return calculateClaimableAmount(ticketTokenId, address(0));
    }

    function calculateClaimableAmount(uint256 ticketTokenId, address claimToken)
        public
        view
        override
        returns (uint256 claimableAmount)
    {
        claimableAmount =
            (streamTotalSupply(claimToken) * shares[ticketTokenId]) /
            totalShares -
            entitlements[ticketTokenId][claimToken].totalClaimed;
    }

    // INTERNAL

    function _updateShares(uint256 tokenId, uint256 newShares) private {
        require(newShares > 0, "DISTRIBUTOR/ZERO_SHARES");

        uint256 prevShares = shares[tokenId];

        shares[tokenId] = newShares;
        totalShares = totalShares + newShares - prevShares;

        emit SharesUpdated(tokenId, prevShares, newShares);
    }

    function _beforeClaim(uint256 ticketTokenId, address claimToken)
        internal
        view
        override
    {
        claimToken;
        require(shares[ticketTokenId] > 0, "DISTRIBUTOR/NO_SHARES");
    }
}
