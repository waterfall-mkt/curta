// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { console } from "forge-std/Test.sol";

import { DeployBase } from "./DeployBase.s.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { MockPuzzle } from "@/utils/mock/MockPuzzle.sol";

contract DeployTest is DeployBase {
    constructor()
        DeployBase(
            // Token renderer:
            ITokenRenderer(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
            // Puzzle:
            IPuzzle(0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E),
            // Owner:
            0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E,
            // Merkle root:
            ""
        )
    { }

    function run() public override {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Deploy the Mock Puzzles
        MockPuzzle mockPuzzleA = new MockPuzzle();
        MockPuzzle mockPuzzleB = new MockPuzzle();

        console.log("Mock Puzzle A Address: ", address(mockPuzzleA));
        console.log("Mock Puzzle B Address: ", address(mockPuzzleB));
        vm.stopBroadcast();

        super.run();
    }

}
