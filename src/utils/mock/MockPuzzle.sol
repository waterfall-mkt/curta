// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPuzzle } from "@/contracts/interfaces/IPuzzle.sol";

/// @title MockPuzzle
/// @author proofofbeef
contract MockPuzzle is IPuzzle {
    // @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return "MockPuzzle";
    }

    // @inheritdoc IPuzzle
    function generate(address _seed) public pure returns (uint256) {
        return uint256(uint160(_seed));
    }

    // @inheritdoc IPuzzle
    function verify(uint256 _start, uint256 _solution) external pure returns (bool) {
        return _start == _solution;
    }

    /// @dev This function is just used as a util function in tests. DO NOT
    /// include a function like this in your puzzle contract.
    /// @param _seed The seed to generate the puzzle from.
    function getSolution(address _seed) external pure returns (uint256) {
        return generate(_seed);
    }
}
