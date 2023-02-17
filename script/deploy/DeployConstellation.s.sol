// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on Constellation.
contract DeployConstellation is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 30 seconds;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = [
        // Pre-funded account
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    ];

    constructor() DeployBase(AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }
}
