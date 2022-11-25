// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IPuzzle
/// @author fiveoutofnine
interface IPuzzle {
    /// @notice Returns the puzzle's name.
    /// @return The puzzle's name.
    function name() external pure returns (string memory);

    /// @notice Generates the puzzle's starting position based on a seed.
    /// @dev The seed is intended to be `msg.sender` of some wrapper function or
    /// call.
    /// @param _seed The seed to use to generate the puzzle.
    /// @return The puzzle's starting position.
    function generate(address _seed) external returns (uint256);

    /// @notice Verifies that a solution is valid for the puzzle.
    /// @dev `_start` is intended to be an output from {IPuzzle-generate}.
    /// @param _start The puzzle's starting position.
    /// @param _solution The solution to the puzzle.
    /// @return Whether the solution is valid.
    function verify(uint256 _start, uint256 _solution) external returns (bool);
}
