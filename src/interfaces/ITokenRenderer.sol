// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenRenderer {
    /// @notice Generates a string of some token's SVG image.
    /// @param _id The ID of a token.
    /// @param _phase The phase the token was solved in.
    /// @return The new URI of a token.
    function render(uint256 _id, uint8 _phase) external view returns (string memory);
}
