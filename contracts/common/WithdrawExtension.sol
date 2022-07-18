// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWithdrawExtension {
    function recipientWithdraw() external;

    function emergencyWithdraw(address[] calldata claimTokens) external;

    function setProceedsRecipient(address _proceedsRecipient) external;

    function lockProceedsRecipient() external;

    function revokeEmergencyPower() external;
}

abstract contract WithdrawExtension is
    IWithdrawExtension,
    Initializable,
    ERC165Storage,
    Ownable
{
    using Address for address;
    using Address for address payable;

    event EmergencyPowerRevoked();
    event EmergencyWithdrawn(address[] claimTokens);

    address public proceedsRecipient;
    bool public proceedsRecipientLocked;
    bool public emergencyPowerRevoked;

    /* INTERNAL */

    function __RecipientWithdrawExtension_init(address _proceedsRecipient)
        internal
        onlyInitializing
    {
        __RecipientWithdrawExtension_init_unchained(_proceedsRecipient);
    }

    function __RecipientWithdrawExtension_init_unchained(
        address _proceedsRecipient
    ) internal onlyInitializing {
        _registerInterface(type(IWithdrawExtension).interfaceId);

        proceedsRecipient = _proceedsRecipient;
    }

    function __EmergencyOwnerWithdrawExtension_init()
        internal
        onlyInitializing
    {
        __EmergencyOwnerWithdrawExtension_init_unchained();
    }

    function __EmergencyOwnerWithdrawExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IWithdrawExtension).interfaceId);
    }

    /* ADMIN */

    function setProceedsRecipient(address _proceedsRecipient)
        external
        onlyOwner
    {
        require(!proceedsRecipientLocked, "Common/RECIPIENT_LOCKED");
        proceedsRecipient = _proceedsRecipient;
    }

    function lockProceedsRecipient() external onlyOwner {
        require(!proceedsRecipientLocked, "Common/RECIPIENT_LOCKED");
        proceedsRecipientLocked = true;
    }

    function recipientWithdraw() external {
        require(proceedsRecipient != address(0), "Common/NO_RECIPIENT");

        uint256 balance = address(this).balance;

        payable(proceedsRecipient).transfer(balance);
    }

    function emergencyWithdraw(address[] calldata claimTokens)
        public
        onlyOwner
    {
        require(!emergencyPowerRevoked, "EMERGENCY_POWER_REVOKED");

        address _owner = owner();

        for (uint256 i = 0; i < claimTokens.length; i++) {
            if (claimTokens[i] == address(0)) {
                payable(_owner).sendValue(address(this).balance);
            } else {
                IERC20(claimTokens[i]).transfer(
                    _owner,
                    IERC20(claimTokens[i]).balanceOf(address(this))
                );
            }
        }
    }

    function revokeEmergencyPower() public onlyOwner {
        emergencyPowerRevoked = true;
        emit EmergencyPowerRevoked();
    }

        /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}
