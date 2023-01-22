// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on Constellation.
contract DeployConstellation is DeployBase {
    /// @notice The merkle root of the Authorship Token.
    bytes32 constant AUTHORSHIP_TOKEN_MERKLE_ROOT = "";

    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    constructor() DeployBase(AUTHORSHIP_TOKEN_MERKLE_ROOT, AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER) { }
}
