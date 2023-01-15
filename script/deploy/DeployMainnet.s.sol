// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployMainnet is DeployBase {
    constructor()
        // Authorship Token Merkle Root
        DeployBase(
            "",
            // Owner
            0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E
        )
    { }
}
