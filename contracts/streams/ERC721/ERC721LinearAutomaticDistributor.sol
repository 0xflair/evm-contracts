// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../common/payments/PaymentRecipientUpgradable.sol";

import "hardhat/console.sol";

contract ERC721LinearAutomaticDistributor is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PaymentRecipientUpgradable
{
    using Address for address;
    using Address for address payable;
    using BitMaps for BitMaps.BitMap;
    using Counters for Counters.Counter;

    string public constant name = "Flair ERC721 Linear Automatic Distributor";

    string public constant version = "0.1";

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct Entitlement {
        uint256 totalClaimed;
        uint256 lastClaimedAt;
    }

    struct Stream {
        address creator;
        address claimToken;
        address ticketToken;
        uint256 emissionRate;
        uint256 claimWindowUnit;
        uint256 claimStart;
        uint256 claimEnd;
    }

    /* Streams incremental ID. */
    Counters.Counter public lastStreamId;

    /* Map of ID to streams. */
    mapping(uint256 => Stream) public streams;

    /* Map of streams to used supply. */
    mapping(uint256 => uint256) public streamUsed;

    /* Map of streams to total supply. */
    mapping(uint256 => uint256) public streamSupply;

    /* Map of streams -> ticket token ID -> entitlement. */
    mapping(uint256 => mapping(uint256 => Entitlement)) public entitlements;

    /* EVENTS */

    event StreamRegistered(
        uint256 indexed streamId,
        address creator,
        address claimToken,
        address ticketToken,
        uint256 emissionRate,
        uint256 claimUnit,
        uint256 claimStart,
        uint256 claimEnd
    );

    event TopUp(address contributor, uint256 indexed streamId, uint256 amount);

    event Claim(
        address claimer,
        uint256 indexed streamId,
        uint256 ticketTokenId,
        uint256 releasedAmount
    );

    event ClaimBulk(
        address claimer,
        uint256 indexed streamId,
        uint256[] ticketTokenIds,
        uint256 releasedAmount
    );

    /* INTERNAL */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /* PUBLIC */

    function registerStream(
        address claimToken,
        address ticketToken,
        uint256 emissionRate,
        uint256 claimWindowUnit,
        uint256 claimStart,
        uint256 claimEnd
    ) public nonReentrant {
        lastStreamId.increment();
        uint256 streamId = lastStreamId.current();

        streams[streamId] = Stream(
            _msgSender(),
            claimToken,
            ticketToken,
            emissionRate,
            claimWindowUnit,
            claimStart,
            claimEnd
        );

        emit StreamRegistered(
            streamId,
            _msgSender(),
            claimToken,
            ticketToken,
            emissionRate,
            claimWindowUnit,
            claimStart,
            claimEnd
        );
    }

    function setEmissionRate(uint256 streamId, uint256 newValue) public {
        require(
            streams[streamId].creator == _msgSender(),
            "DISTRIBUTOR/NOT_OWNER"
        );

        streams[streamId].emissionRate = newValue;
    }

    function setClaimDurationUnit(uint256 streamId, uint256 newValue) public {
        require(
            streams[streamId].creator == _msgSender(),
            "DISTRIBUTOR/NOT_OWNER"
        );

        streams[streamId].claimWindowUnit = newValue;
    }

    function setClaimStart(uint256 streamId, uint256 newValue) public {
        require(
            streams[streamId].creator == _msgSender(),
            "DISTRIBUTOR/NOT_OWNER"
        );

        streams[streamId].claimStart = newValue;
    }

    function setClaimEnd(uint256 streamId, uint256 newValue) public {
        require(
            streams[streamId].creator == _msgSender(),
            "DISTRIBUTOR/NOT_OWNER"
        );

        streams[streamId].claimEnd = newValue;
    }

    function topUp(uint256 streamId, uint256 amount)
        public
        payable
        nonReentrant
    {
        require(
            streams[streamId].creator != address(0),
            "DISTRIBUTOR/WRONG_STREAM"
        );
        require(amount > 0, "DISTRIBUTOR/MISSING_AMOUNT");

        if (streams[streamId].claimToken == address(0)) {
            require(msg.value == amount, "DISTRIBUTOR/INCORRECT_PAYMENT");
        } else {
            IERC20(streams[streamId].claimToken).transferFrom(
                _msgSender(),
                address(this),
                amount
            );
        }

        streamSupply[streamId] += amount;

        emit TopUp(_msgSender(), streamId, amount);
    }

    function claim(uint256 streamId, uint256 ticketTokenId)
        public
        nonReentrant
    {
        /* CHECKS */
        require(
            streams[streamId].creator != address(0),
            "DISTRIBUTOR/WRONG_STREAM"
        );
        require(
            streams[streamId].claimStart < block.timestamp,
            "DISTRIBUTOR/NOT_STARTED"
        );
        require(
            streamSupply[streamId] - streamUsed[streamId] > 0,
            "DISTRIBUTOR/STREAM_EMPTY"
        );

        require(
            entitlements[streamId][ticketTokenId].lastClaimedAt <
                block.timestamp - streams[streamId].claimWindowUnit,
            "DISTRIBUTOR/TOO_EARLY"
        );
        require(
            IERC721(streams[streamId].ticketToken).ownerOf(ticketTokenId) ==
                _msgSender(),
            "DISTRIBUTOR/NOT_NFT_OWNER"
        );

        uint256 releasedAmount = calculateClaimableAmountRounded(
            streamId,
            ticketTokenId
        );
        require(releasedAmount > 0, "DISTRIBUTOR/NOTHING_TO_CLAIM");

        require(
            streamSupply[streamId] - streamUsed[streamId] >= releasedAmount,
            "DISTRIBUTOR/STREAM_DEPLETED"
        );

        /* EFFECTS */

        streamUsed[streamId] += releasedAmount;

        entitlements[streamId][ticketTokenId].totalClaimed += releasedAmount;
        entitlements[streamId][ticketTokenId].lastClaimedAt = block.timestamp;

        /* INTERACTIONS */

        if (streams[streamId].claimToken == address(0)) {
            payable(address(_msgSender())).sendValue(releasedAmount);
        } else {
            IERC20(streams[streamId].claimToken).transfer(
                _msgSender(),
                releasedAmount
            );
        }

        /* LOGS */

        emit Claim(_msgSender(), streamId, ticketTokenId, releasedAmount);
    }

    function claimBulk(uint256 streamId, uint256[] calldata ticketTokenIds)
        public
        nonReentrant
    {
        /* CHECKS */
        require(
            streams[streamId].creator != address(0),
            "DISTRIBUTOR/WRONG_STREAM"
        );
        require(
            streams[streamId].claimStart < block.timestamp,
            "DISTRIBUTOR/NOT_STARTED"
        );
        require(
            streamSupply[streamId] - streamUsed[streamId] > 0,
            "DISTRIBUTOR/STREAM_EMPTY"
        );

        uint256 totalClaimableAmount;
        uint256 lastClaimCheckpoint = block.timestamp -
            streams[streamId].claimWindowUnit;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            /* CHECKS */
            require(
                entitlements[streamId][ticketTokenIds[i]].lastClaimedAt <
                    lastClaimCheckpoint,
                "DISTRIBUTOR/TOO_EARLY"
            );
            require(
                IERC721(streams[streamId].ticketToken).ownerOf(
                    ticketTokenIds[i]
                ) == _msgSender(),
                "DISTRIBUTOR/NOT_NFT_OWNER"
            );

            /* EFFECTS */

            uint256 claimableAmount = calculateClaimableAmountRounded(
                streamId,
                ticketTokenIds[i]
            );

            if (claimableAmount > 0) {
                totalClaimableAmount += claimableAmount;

                entitlements[streamId][ticketTokenIds[i]]
                    .totalClaimed += claimableAmount;
                entitlements[streamId][ticketTokenIds[i]].lastClaimedAt = block
                    .timestamp;
            }
        }

        require(
            streamSupply[streamId] - streamUsed[streamId] >=
                totalClaimableAmount,
            "DISTRIBUTOR/STREAM_DEPLETED"
        );

        streamUsed[streamId] += totalClaimableAmount;

        /* INTERACTIONS */

        if (streams[streamId].claimToken == address(0)) {
            payable(address(_msgSender())).sendValue(totalClaimableAmount);
        } else {
            IERC20(streams[streamId].claimToken).transfer(
                _msgSender(),
                totalClaimableAmount
            );
        }

        /* LOGS */

        emit ClaimBulk(
            _msgSender(),
            streamId,
            ticketTokenIds,
            totalClaimableAmount
        );
    }

    /* READ ONLY */

    function getInfo(uint256 streamId)
        public
        view
        returns (
            Stream memory stream,
            uint256 supply,
            uint256 used
        )
    {
        stream = streams[streamId];
        supply = streamSupply[streamId];
        used = streamUsed[streamId];
    }

    function getEntitlement(uint256 streamId, uint256 ticketTokenId)
        public
        view
        returns (Entitlement memory)
    {
        return entitlements[streamId][ticketTokenId];
    }

    function getTotalClaimedBulk(
        uint256 streamId,
        uint256[] calldata ticketTokenIds
    ) public view returns (uint256) {
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalClaimed += getEntitlement(streamId, ticketTokenIds[i])
                .totalClaimed;
        }

        return totalClaimed;
    }

    function getTotalClaimableBulk(
        uint256 streamId,
        uint256[] calldata ticketTokenIds
    ) public view returns (uint256) {
        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalClaimable += calculateClaimableAmountRounded(
                streamId,
                ticketTokenIds[i]
            );
        }

        return totalClaimable;
    }

    function calculateClaimableAmountRounded(
        uint256 streamId,
        uint256 ticketTokenId
    ) public view returns (uint256 claimableAmount) {
        claimableAmount =
            calculateReleasedAmountRounded(
                streamId,
                block.timestamp > streams[streamId].claimEnd
                    ? streams[streamId].claimEnd
                    : block.timestamp
            ) -
            entitlements[streamId][ticketTokenId].totalClaimed;
    }

    function calculateReleasedAmountRounded(uint256 streamId, uint256 calcUntil)
        public
        view
        returns (uint256)
    {
        if (calcUntil < streams[streamId].claimStart) {
            return 0;
        }

        return
            streams[streamId].emissionRate *
            // Intentionally rounded down:
            ((calcUntil - streams[streamId].claimStart) /
                streams[streamId].claimWindowUnit);
    }

    function calculateClaimableAmountFractioned(
        uint256 streamId,
        uint256 ticketTokenId
    ) public view returns (uint256 claimableAmount) {
        claimableAmount =
            calculateReleasedAmountFractioned(
                streamId,
                block.timestamp > streams[streamId].claimEnd
                    ? streams[streamId].claimEnd
                    : block.timestamp
            ) -
            entitlements[streamId][ticketTokenId].totalClaimed;
    }

    function calculateReleasedAmountFractioned(
        uint256 streamId,
        uint256 calcUntil
    ) public view returns (uint256) {
        return
            ((calcUntil - streams[streamId].claimStart) *
                streams[streamId].emissionRate) /
            streams[streamId].claimWindowUnit;
    }
}
