// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPuzzle } from "@/interfaces/IPuzzle.sol";

/// @title CollatzPuzzle
/// @author fiveoutofnine
contract CollatzPuzzle is IPuzzle {
    // @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return "Collatz";
    }

    /// @inheritdoc IPuzzle
    function generate(address _seed) external pure returns (uint256) {
        // The last 8 bits denote the number of times to apply the operation.
        // We want to apply it at least once, hence `| 1`.
        return uint256(keccak256(abi.encodePacked(_seed))) | 1;
    }

    /// @inheritdoc IPuzzle
    function verify(uint256 _start, uint256 _solution) external pure returns (bool) {
        // Retrieve the last 8 bits.
        uint256 iterations = _start & 0xFF;

        for (uint256 i = 0; i < iterations; ) {
            unchecked {
                // Collatz Operation
                if (_start & 1 == 0) _start >>= 1;
                else                 _start = 3 * _start + 1;

                ++i;
            }
        }

        return _start == _solution;
    }
}
