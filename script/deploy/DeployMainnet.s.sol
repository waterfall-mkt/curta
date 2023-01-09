// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";

contract DeployMainnet is DeployBase {
    constructor()
        // Token renderer:
        DeployBase(
            ITokenRenderer(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
            // Puzzle:
            IPuzzle(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
            // Owner:
            0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E
        )
    { }
}
