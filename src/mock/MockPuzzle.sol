// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPuzzle } from "../interfaces/IPuzzle.sol";

// @title MockPuzzle
// @author proofofbeef
contract MockPuzzle is IPuzzle {

    // @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return "MockPuzzle";
    }

    // @inheritdoc IPuzzle
    function generate(address _seed) external returns (uint256) {
        return uint256(uint160(_seed));
    }

    // @inheritdoc IPuzzle
    function verify(uint256 _start, uint256 _solution) external returns (bool) {
        return _solution == 1;
    }

}