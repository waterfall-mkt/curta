// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { FlagRenderer } from "@/contracts/FlagRenderer.sol";
import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { MockPuzzle } from "@/contracts/utils/mock/MockPuzzle.sol";

/// @notice A script to print the token URI returned by `Curta` for testing
/// purposes.
contract PrintFlagTokenScript is Script {
    /// @notice The instance of `FlagRenderer` that will be deployed after the
    /// script runs.
    FlagRenderer internal flagRenderer;

    /// @notice The instance of `MockPuzzle` that will be deployed after the
    /// script runs.
    MockPuzzle internal puzzle;

    /// @notice Deploys an instance of `FlagRenderer` and prints a sample token
    /// URI output.
    function run() public {
        puzzle = new MockPuzzle();

        ICurta.PuzzleData memory puzzleData = ICurta.PuzzleData({
            puzzle: puzzle,
            addedTimestamp: uint40(block.timestamp), // This does not affect the output.
            firstSolveTimestamp: 0 // This does not affect the output.
         });

        flagRenderer = new FlagRenderer();
        console.log(
            flagRenderer.render({
                _puzzleData: puzzleData,
                _tokenId: (31 << 128) | 21_563,
                _author: address(0),
                _solveTime: uint40(49 days + 23 minutes + 17 seconds),
                _solveMetadata: uint56((0xABCDEF0 << 28) | 0x12345),
                _phase: 0,
                _solves: 256,
                _colors: 0x181E28181E2827303DF0F6FC94A3B3
            })
        );
    }
}
