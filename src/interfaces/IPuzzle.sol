// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for a puzzle on Curta
/// @notice The goal of players is to view the source code of the puzzle (may
/// range from just the bytecode to Solidity—whatever the author wishes to
/// provide), interpret the code, solve it as if it was a regular puzzle, then
/// verify the solution on-chain.
/// @dev Since puzzles are on-chain, everyone can view everyone else's
/// submissions. The generative aspect prevents front-running and allows for
/// multiple winners: even if players view someone else's solution, they still
/// have to figure out what the rules/constraints of the puzzle are and apply
/// the solution to their respective starting position.
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
