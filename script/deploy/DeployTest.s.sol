// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { console } from "forge-std/Test.sol";

import { DeployBase } from "./DeployBase.s.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { MockPuzzle } from "@/utils/mock/MockPuzzle.sol";

/// @notice A script to deploy the protocol for testing purposes. In addition to
/// deploying Curta, 2 mock puzzles are deployed.
contract DeployTest is DeployBase {
    bytes32 AUTHORSHIP_TOKEN_MERKLE_ROOT = "";
    address OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    constructor()
        DeployBase(
            AUTHORSHIP_TOKEN_MERKLE_ROOT,
            OWNER
        )
    { }

    /// @notice See description for {DeployTest}.
    function run() public override {
        // Read private key from the environment.
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // ---------------------------------------------------------------------
        // As `deployerKey`
        // ---------------------------------------------------------------------

        vm.startBroadcast(deployerKey);

        // Deploy 2 instances of `MockPuzzle` to serve as mock puzzles for
        // testing purposes.
        MockPuzzle mockPuzzle1 = new MockPuzzle();
        MockPuzzle mockPuzzle2 = new MockPuzzle();

        vm.stopBroadcast();

        console.log("Mock Puzzle 1 Address: ", address(mockPuzzle1));
        console.log("Mock Puzzle 2 Address: ", address(mockPuzzle2));

        super.run();
    }
}
