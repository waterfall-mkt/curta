// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on Goerli.
contract DeployGoerli is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 3 days;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = new address[](0);

    constructor() DeployBase(AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }
}
