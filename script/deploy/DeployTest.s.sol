// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { console } from "forge-std/Test.sol";

import { DeployBase } from "./DeployBase.s.sol";
import { MockPuzzle } from "@/contracts/utils/mock/MockPuzzle.sol";

/// @notice A script to deploy the protocol for testing purposes. In addition to
/// deploying Curta, 2 mock puzzles are deployed.
contract DeployTest is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0x7A0E5c5e5E5E5E5E5E5e5E5e5E5E5E5E5E5E5e5E;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 10 seconds;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = new address[](0);

    constructor() DeployBase(AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }

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
