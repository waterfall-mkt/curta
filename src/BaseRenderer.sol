// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibString } from "solmate/utils/LibString.sol";

import { ITokenRenderer } from "@/contracts/interfaces/ITokenRenderer.sol";

contract BaseRenderer is ITokenRenderer {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    uint256 private constant UINT_LUT = 0x46454443424139383736353433323130;

    /// @notice The SVG header.
    string constant SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8">';

    /// @notice The SVG footer.
    string constant SVG_FOOTER = "</svg>";

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @inheritdoc ITokenRenderer
    function render(uint256 _id, uint8 _phase) external pure override returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_id)));
        // TODO: if (_phase == 1) return shields;

        uint256 fill = seed & 0xFFFFFF;
        seed >>= 24;

        string memory svg = SVG_HEADER;
        for (uint256 i = 0xEFAE78CF2C70AEAA688E28606DA6584D24502CA2480C2040; i != 0; i >>= 6) {
            if (seed & 1 == 1) {
                (uint256 x, uint256 y) = (i & 7, (i >> 3) & 7);
                uint256 darkenedFill = darkenColor(fill, _phase == 2 ? seed & 3 : 0);

                svg = string.concat(svg, rect(x, y, darkenedFill));
                unchecked {
                    svg = string.concat(svg, rect(7 - x, y, darkenedFill));
                }
            }

            seed >>= 1;
        }

        return string.concat(svg, SVG_FOOTER);
    }

    function rect(uint256 _x, uint256 _y, uint256 _fill) internal pure returns (string memory) {
        return string.concat(
            '<rect width="1" height="1" x="',
            LibString.toString(_x),
            '" y="',
            LibString.toString(_y),
            '" fill="#',
            toHexString(_fill),
            '" />'
        );
    }

    function toHexString(uint256 _a) internal pure returns (string memory) {
        bytes memory b = new bytes(32);

        uint256 data = (((UINT_LUT >> (((_a >> 20) & 0xF) << 3)) & 0xFF) << 40)
            | (((UINT_LUT >> (((_a >> 16) & 0xF) << 3)) & 0xFF) << 32)
            | (((UINT_LUT >> (((_a >> 12) & 0xF) << 3)) & 0xFF) << 24)
            | (((UINT_LUT >> (((_a >> 8) & 0xF) << 3)) & 0xFF) << 16)
            | (((UINT_LUT >> (((_a >> 4) & 0xF) << 3)) & 0xFF) << 8)
            | ((UINT_LUT >> ((_a & 0xF) << 3)) & 0xFF);

        assembly {
            mstore(add(b, 32), data)
        }

        return string(b);
    }

    function darkenColor(uint256 _color, uint256 _num) internal pure returns (uint256) {
        return (((_color >> 0x10) >> _num) << 0x10) | ((((_color >> 8) & 0xFF) >> _num) << 8)
            | ((_color & 0xFF) >> _num);
    }
}
