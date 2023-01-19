// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on mainnet.
contract DeployMainnet is DeployBase {
    /// @notice The merkle root of the Authorship Token.
    bytes32 constant AUTHORSHIP_TOKEN_MERKLE_ROOT = "";

    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    constructor() DeployBase(AUTHORSHIP_TOKEN_MERKLE_ROOT, AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER) { }
}
