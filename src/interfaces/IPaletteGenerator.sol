// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for a palette generator.
/// @author fiveoutofnine
/// @dev `IPaletteGenerator` contains generator functions for a color's red,
/// green, and blue color values. Each of these functions is intended to take in
/// a 18 decimal fixed-point number in [0, 1] representing the position in the
/// colormap and return the corresponding 18 decimal fixed-point number in
/// [0, 1] representing the value of each respective color.
interface IPaletteGenerator {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Reverts if the position is not a valid input.
    /// @dev The position is not a valid input if it is greater than 1e18.
    /// @param _position Position in the colormap.
    error InvalidPosition(uint256 _position);

    // -------------------------------------------------------------------------
    // Generators
    // -------------------------------------------------------------------------

    /// @notice Computes the intensity of red of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of red in that color at the position
    /// `_position`.
    function r(uint256 _position) external pure returns (uint256);

    /// @notice Computes the intensity of green of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of green in that color at the position
    /// `_position`.
    function g(uint256 _position) external pure returns (uint256);

    /// @notice Computes the intensity of blue of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of blue in that color at the position
    /// `_position`.
    function b(uint256 _position) external pure returns (uint256);
}
