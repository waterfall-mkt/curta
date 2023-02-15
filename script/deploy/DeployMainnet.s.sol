// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on mainnet.
contract DeployMainnet is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 3 days;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = new address[](0);

    constructor() DeployBase(AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }
}
