// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on Constellation.
contract DeployConstellation is DeployBase {
    /// @notice The merkle root of the authorship token.
    bytes32 constant AUTHORSHIP_TOKEN_MERKLE_ROOT = "";

    /// @notice The address to transfer the ownership of the authorship token
    /// to.
    address constant OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    constructor() DeployBase(AUTHORSHIP_TOKEN_MERKLE_ROOT, OWNER) { }
}
