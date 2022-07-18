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
    function withdraw(address[] calldata claimTokens) external;

    function setWithdrawRecipient(address _withdrawRecipient) external;

    function lockWithdrawRecipient() external;

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

    address public withdrawRecipient;
    bool public withdrawRecipientLocked;
    bool public emergencyPowerRevoked;


    /* INTERNAL */

    function __RecipientWithdrawExtension_init(address _withdrawRecipient)
        internal
        onlyInitializing
    {
        __RecipientWithdrawExtension_init_unchained(_withdrawRecipient);
    }

    function __RecipientWithdrawExtension_init_unchained(
        address _withdrawRecipient
    ) internal onlyInitializing {
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

    function withdraw(address[] calldata claimTokens)
        external
        onlyOwner
    {
        // withdraw by recipient
        if (withdrawRecipient != address(0)) {
            require(withdrawRecipient != address(0), "WITHDRAW/NO_RECIPIENT");

            uint256 balance = address(this).balance;

            payable(withdrawRecipient).transfer(balance);
        // emergency withdraw
        } else {
            require(!emergencyPowerRevoked, "WITHDRAW/EMERGENCY_POWER_REVOKED");

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
    }

    function withdrawByAmount(uint256 amount) {
        require(withdrawRecipient != address(0), "WITHDRAW/NO_RECIPIENT");
        require(!amount, "WITHDRAW/NO_AMOUNT");

        uint256 balance = address(this).balance;
        require(amount =< balance, "WITHDRAW/NOT_SUFFICIENT_BALANCE");

        payable(withdrawRecipient).transfer(amount);
    }

    function revokeEmergencyPower() external onlyOwner {
        emergencyPowerRevoked = true;
        emit EmergencyPowerRevoked();
    }


    /* PUBLIC */
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override(ERC165Storage)
    //     returns (bool)
    // {
    //     return ERC165Storage.supportsInterface(interfaceId);
    // }
}
