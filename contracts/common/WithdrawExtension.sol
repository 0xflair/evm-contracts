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
    function withdraw(
        address[] calldata claimTokens,
        uint256[] calldata amounts
    ) external;

    function setWithdrawRecipient(address _withdrawRecipient) external;

    function lockWithdrawRecipient() external;

    function revokeWithdrawPower() external;
}

abstract contract WithdrawExtension is
    IWithdrawExtension,
    Initializable,
    Ownable,
    ERC165Storage
{
    using Address for address;
    using Address for address payable;

    event WithdrawPowerRevoked();
    event Withdrawn(address[] claimTokens, uint256[] amounts);

    address public withdrawRecipient;
    bool public withdrawRecipientLocked;
    bool public withdrawPowerRevoked;

    /* INTERNAL */

    function __WithdrawExtension_init(address _withdrawRecipient)
        internal
        onlyInitializing
    {
        __WithdrawExtension_init_unchained(_withdrawRecipient);
    }

    function __WithdrawExtension_init_unchained(address _withdrawRecipient)
        internal
        onlyInitializing
    {
        _registerInterface(type(IWithdrawExtension).interfaceId);

        withdrawRecipient = _withdrawRecipient;
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

    function setWithdrawRecipient(address _withdrawRecipient)
        external
        onlyOwner
    {
        require(!withdrawRecipientLocked, "WITHDRAW/RECIPIENT_LOCKED");
        withdrawRecipient = _withdrawRecipient;
    }

    function lockWithdrawRecipient() external onlyOwner {
        require(!withdrawRecipientLocked, "WITHDRAW/RECIPIENT_LOCKED");
        withdrawRecipientLocked = true;
    }

    function withdraw(
        address[] calldata claimTokens,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(withdrawRecipient != address(0), "WITHDRAW/NO_RECIPIENT");
        require(!withdrawPowerRevoked, "WITHDRAW/EMERGENCY_POWER_REVOKED");

        for (uint256 i = 0; i < claimTokens.length; i++) {
            if (claimTokens[i] == address(0)) {
                payable(withdrawRecipient).sendValue(amounts[i]);
            } else {
                IERC20(claimTokens[i]).transfer(withdrawRecipient, amounts[i]);
            }
        }

        emit Withdrawn(claimTokens, amounts);
    }

    function revokeWithdrawPower() external onlyOwner {
        withdrawPowerRevoked = true;
        emit WithdrawPowerRevoked();
    }
}
