// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";

contract DeployTest is DeployBase {
    constructor()
        DeployBase(
            ITokenRenderer(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
            // Owner:
            0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E
        )
    { }

    function run() external {
        // Deploy the Mock Puzzles
        MockPuzzle mockPuzzleA = new MockPuzzle();
        MockPuzzle mockPuzzleB = new MockPuzzle();

        console.log("Mock Puzzle A Address: ", address(mockPuzzleA));
        console.log("Mock Puzzle B Address: ", address(mockPuzzleB));
    }

}
