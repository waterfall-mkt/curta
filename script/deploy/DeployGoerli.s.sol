// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on Goerli.
contract DeployGoerli is DeployBase {
    bytes32 AUTHORSHIP_TOKEN_MERKLE_ROOT = "";
    address OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    constructor()
        DeployBase(
            AUTHORSHIP_TOKEN_MERKLE_ROOT,
            OWNER
        )
    { }
}
