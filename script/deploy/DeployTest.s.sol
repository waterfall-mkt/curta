// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../src/BaseRenderer.sol";
import "../../src/mock/MockPuzzle.sol";
import { DeployBase } from "./DeployBase.s.sol";
import { ITokenRenderer } from "../../src/interfaces/ITokenRenderer.sol";

contract DeployTest is DeployBase {
    constructor()
    // Values below are all bogus and not used for testing purposes.
        DeployBase(
            // Token renderer:
            ITokenRenderer(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
            // Puzzle:
            IPuzzle(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
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
