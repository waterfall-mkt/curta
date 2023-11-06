// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPaletteGenerator } from "@/contracts/interfaces/IPaletteGenerator.sol";

/// @title The interface for the colormap registry.
/// @author fiveoutofnine
/// @dev A colormap may be defined in 2 ways: (1) via segment data and (2) via a
/// ``palette generator.''
///     1. via segment data
///     2. or via a palette generator ({IPaletteGenerator}).
/// Segment data contains 1 `uint256` each for red, green, and blue describing
/// their intensity values along the colormap. Each `uint256` contains 24-bit
/// words bitpacked together with the following structure (bits are
/// right-indexed):
///     | Bits      | Meaning                                              |
///     | --------- | ---------------------------------------------------- |
///     | `23 - 16` | Position in the colormap the segment begins from     |
///     | `15 - 08` | Intensity of R, G, or B the previous segment ends at |
///     | `07 - 00` | Intensity of R, G, or B the next segment starts at   |
/// Given some position, the output will be computed via linear interpolations
/// on the segment data for R, G, and B. A maximum of 10 of these segments fit
/// within 256 bits, so up to 9 segments can be defined. If you need more
/// granularity or a nonlinear palette function, you may implement
/// {IPaletteGenerator} and define a colormap with that.
interface IColormapRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when a colormap already exists.
    /// @param _hash Hash of the colormap's definition.
    error ColormapAlreadyExists(bytes8 _hash);

    /// @notice Emitted when a colormap does not exist.
    /// @param _hash Hash of the colormap's definition.
    error ColormapDoesNotExist(bytes8 _hash);

    /// @notice Emitted when a segment data used to define a colormap does not
    /// follow the representation outlined in {IColormapRegistry}.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    error SegmentDataInvalid(uint256 _segmentData);

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice Segment data that defines a colormap when read via piece-wise
    /// linear interpolation.
    /// @dev Each param contains 24-bit words, so each one may contain at most
    /// 9 (24*10 - 1) segments. See {IColormapRegistry} for how the segment data
    /// should be structured.
    /// @param r Segment data for red's color value along the colormap.
    /// @param g Segment data for green's color value along the colormap.
    /// @param b Segment data for blue's color value along the colormap.
    struct SegmentData {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a colormap is registered via a palette generator
    /// function.
    /// @param _hash Hash of `_paletteGenerator`.
    /// @param _paletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    event RegisterColormap(bytes8 _hash, IPaletteGenerator _paletteGenerator);

    /// @notice Emitted when a colormap is registered via segment data.
    /// @param _hash Hash of `_segmentData`.
    /// @param _segmentData Segment data defining the colormap.
    event RegisterColormap(bytes8 _hash, SegmentData _segmentData);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @param _hash Hash of the colormap's definition (palette generator).
    /// @return IPaletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    function paletteGenerators(bytes8 _hash) external view returns (IPaletteGenerator);

    /// @param _hash Hash of the colormap's definition (segment data).
    /// @return uint256 Segment data for red's color value along the colormap.
    /// @return uint256 Segment data for green's color value along the colormap.
    /// @return uint256 Segment data for blue's color value along the colormap.
    function segments(bytes8 _hash) external view returns (uint256, uint256, uint256);

    // -------------------------------------------------------------------------
    // Actions
    // -------------------------------------------------------------------------

    /// @notice Batch register colormaps with palette generators.
    /// @param _paletteGenerators Array of {IPaletteGenerator} instances for the
    /// colormap.
    function batchRegister(IPaletteGenerator[] memory _paletteGenerators) external;

    /// @notice Batch register colormaps with segment data that will be read
    /// via piece-wise linear interpolation.
    /// @dev See {IColormapRegistry} for how the segment data should be
    /// structured.
    /// @param _segmentDataArray Array of segment data tuples defining the
    /// colormap.
    function batchRegister(SegmentData[] memory _segmentDataArray) external;

    /// @notice Register a colormap with a palette generator.
    /// @param _paletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    function register(IPaletteGenerator _paletteGenerator) external;

    /// @notice Register a colormap with segment data that will be read via
    /// piece-wise linear interpolation.
    /// @dev See {IColormapRegistry} for how the segment data should be
    /// structured.
    /// @param _segmentData Segment data defining the colormap.
    function register(SegmentData memory _segmentData) external;

    // -------------------------------------------------------------------------
    // View
    // -------------------------------------------------------------------------

    /// @notice Get the red, green, and blue color values of a color in a
    /// colormap at some position.
    /// @dev Each color value will be returned as a 18 decimal fixed-point
    /// number in [0, 1]. Note that the function *will not* revert if
    /// `_position` is an invalid input (i.e. greater than 1e18). This
    /// responsibility is left to the implementation of {IPaletteGenerator}s.
    /// @param _hash Hash of the colormap's definition.
    /// @param _position 18 decimal fixed-point number in [0, 1] representing
    /// the position in the colormap (i.e. 0 being min, and 1 being max).
    /// @return uint256 Intensity of red in that color at the position
    /// `_position`.
    /// @return uint256 Intensity of green in that color at the position
    /// `_position`.
    /// @return uint256 Intensity of blue in that color at the position
    /// `_position`.
    function getValue(bytes8 _hash, uint256 _position)
        external
        view
        returns (uint256, uint256, uint256);

    /// @notice Get the hexstring for a color in a colormap at some position.
    /// @param _hash Hash of the colormap's definition.
    /// @param _position Position in the colormap (i.e. 0 being min, and 255
    /// being max).
    /// @return string Hexstring excluding ``#'' (e.g. `007CFF`) of the color
    /// at the position `_position`.
    function getValueAsHexString(bytes8 _hash, uint8 _position)
        external
        view
        returns (string memory);

    /// @notice Get the red, green, and blue color values of a color in a
    /// colormap at some position.
    /// @dev Each color value will be returned as a `uint8` number in [0, 255].
    /// @param _hash Hash of the colormap's definition.
    /// @param _position Position in the colormap (i.e. 0 being min, and 255
    /// being max).
    /// @return uint8 Intensity of red in that color at the position
    /// `_position`.
    /// @return uint8 Intensity of green in that color at the position
    /// `_position`.
    /// @return uint8 Intensity of blue in that color at the position
    /// `_position`.
    function getValueAsUint8(bytes8 _hash, uint8 _position)
        external
        view
        returns (uint8, uint8, uint8);
}
