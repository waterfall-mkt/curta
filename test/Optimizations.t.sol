// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

/// @notice Various tests to test the correctness of obscure/esoteric
/// optimizations.
contract OptimizationsTest is Test {
    /// @dev Copied from {Curta}.
    uint256 constant PHASE_ONE_LENGTH = 2 days;

    /// @dev Copied from {Curta}.
    uint256 constant SUBMISSION_LENGTH = 5 days;

    /// @notice Fuzz test the branchless optimization of computing the phase
    /// from solve timestamp against a more readable, branched version.
    /// @param _firstSolveTimestamp The timestamp of the first solve (if any).
    /// @param _solveTimestamp The timestamp of the solve to analyze.
    function testFuzzComputePhaseFromTimestampBranchlessOptimization(
        uint40 _firstSolveTimestamp,
        uint40 _solveTimestamp
    ) public {
        vm.assume(_firstSolveTimestamp < _solveTimestamp);

        uint8 branchlessPhase;
        uint8 branchedPhase;

        // Branchless version
        assembly {
            branchlessPhase :=
                mul(
                    iszero(iszero(_firstSolveTimestamp)),
                    add(
                        1,
                        add(
                            gt(_solveTimestamp, add(_firstSolveTimestamp, PHASE_ONE_LENGTH)),
                            gt(_solveTimestamp, add(_firstSolveTimestamp, SUBMISSION_LENGTH))
                        )
                    )
                )
        }

        // Branched version.
        if (_firstSolveTimestamp == 0) {
            branchedPhase = 0;
        } else {
            if (_solveTimestamp > _firstSolveTimestamp + SUBMISSION_LENGTH) {
                branchedPhase = 3;
            } else if (_solveTimestamp > _firstSolveTimestamp + PHASE_ONE_LENGTH) {
                branchedPhase = 2;
            } else {
                branchedPhase = 1;
            }
        }

        assertEq(branchlessPhase, branchedPhase);
    }
}
