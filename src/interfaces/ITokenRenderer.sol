// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for puzzle's token renderers on Curta
/// @notice A token renderer is responsible for generating a token's image URI,
/// which will be returned as part of the token's URI. Curta comes with a base
/// renderer initialized at deploy, but a puzzle author may set a custom token
/// renderer contract. If it is not set, Curta's base renderer will be used.
/// @dev The image URI must be a valid SVG image.
interface ITokenRenderer {
    /// @notice Generates a string of some token's SVG image.
    /// @param _id The ID of a token.
    /// @param _phase The phase the token was solved in.
    /// @return The new URI of a token.
    function render(uint256 _id, uint8 _phase) external view returns (string memory);
}
