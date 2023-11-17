// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployBaseGoerli is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 3 days;

    /// @notice Address of the create2 deployer used for deploying
    /// the `FlagRenderer` and `AuthorshipToken` contracts.
    /// @dev https://github.com/pcaversaccio/create2deployer
    address constant CREATE2DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = [
        // fiveoutofnine.eth
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        // sabnock.eth
        0xDbAacdcadD7c51a325B771ff75B261a1e7baE11c
    ];

    constructor() DeployBase(CREATE2DEPLOYER, AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }
}