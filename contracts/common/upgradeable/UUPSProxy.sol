// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract UUPSProxy is ERC1967Proxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(
            _ADMIN_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
        );
        _changeAdmin(_admin);
    }

    function getImplementation()
        external
        view
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }
}
