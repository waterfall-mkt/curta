// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Base64 } from "solady/utils/Base64.sol";
import { LibString } from "solady/utils/LibString.sol";

import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { IColormapRegistry } from "@/contracts/interfaces/IColormapRegistry.sol";

/// @title Curta Flag Renderer
/// @author fiveoutofnine
/// @notice A contract that renders the JSON and SVG for a Flag token.
contract FlagRenderer {
    using LibString for uint256;
    using LibString for address;
    using LibString for string;

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The colormap registry.
    /// @dev v0.0.2
    IColormapRegistry constant colormapRegistry =
        IColormapRegistry(0x00000000A84FcdF3E9C165e6955945E87dA2cB0D);

    /// @notice Render the JSON and SVG for a Flag token.
    /// @param _puzzleData The puzzle data.
    /// @param _tokenId The token ID.
    /// @param _author The author of the puzzle.
    /// @param _solveTime The time it took to solve the puzzle.
    /// @param _solveMetadata The metadata associated with the solve.
    /// @param _phase The phase of the puzzle.
    /// @param _solves The number of solves the puzzle has.
    /// @param _colors The colors of the Flag.
    /// @return string memory The JSON and SVG for the Flag token.
    function render(
        ICurta.PuzzleData memory _puzzleData,
        uint256 _tokenId,
        address _author,
        uint40 _solveTime,
        uint56 _solveMetadata,
        uint8 _phase,
        uint32 _solves,
        uint120 _colors
    ) external view returns (string memory) {
        // Generate the puzzle's attributes.
        string memory attributes;
        {
            attributes = string.concat(
                '[{"trait_type":"Puzzle","value":"',
                _puzzleData.puzzle.name(),
                '"},{"trait_type":"Puzzle ID","value":',
                uint256(_tokenId >> 128).toString(),
                '},{"trait_type":"Author","value":"',
                _author.toHexStringChecksumed(),
                '"},{"trait_type":"Phase","value":"',
                uint256(_phase).toString(),
                '"},{"trait_type":"Solver","value":"',
                _formatValueAsAddress(uint256(_solveMetadata >> 28)),
                '"},{"trait_type":"Solve time","value":',
                uint256(_solveTime).toString(),
                '},{"trait_type":"Rank","value":',
                uint256(uint128(_tokenId)).toString(),
                "}]"
            );
        }

        // Generate the puzzle's SVG.
        string memory image;
        {
            image = string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="550" height="550" viewBox="0 0 550 '
                '550"><style>@font-face{font-family:A;src:url(data:font/woff2;charset-utf-8;base64,'
                "d09GMgABAAAAABIoABAAAAAAKLAAABHJAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGjobkE4ci2AGYD9TVE"
                "FURACBHBEICqccoBELgRYAATYCJAOCKAQgBYNuByAMBxt3I6OimvUVZH+VwJOd1yhF0zgE5TExCEqYGJii"
                "xbbnwP4dZ3ojLIOo9nusZ/fRJ8AQgAICFZmKIpSpqJRPjvUpssca0NE7gG12KCpiscLIQJvXhQltNGlMwA"
                "rs/BmdK5fVh2tlJjmcJIfyqegIjKaFAkL2xmzu3G5f+LKucK0RgScgqNbInt05eA7IdyHLQlJ5ILKkAI2L"
                "smRUYiTh5D8sgBvNUikgepThvv9/7Vt9l9274oNYWrFooc1GREOjlHln5tu8NRvMZ1WEJN6I4hZFQyGaVu"
                "tEQvmh0iqJSMiE1ggNX4fm60G4VBK+hVS6yPZZNHETOvYf/6wI8AMAxSaiREKCqKkRPT1iaEjMNZdYzh2C"
                "AK+6KbX/oC8NZO9cTOaDLAPg/gNAbl9N5AMKCBAGxaF4IxHCbAZIOiZOprfyvA2svxHYCN8xFXIgBO2JgJ"
                "BkCIqIycqraOuabY655plvgYUWWWyJFXbwhFCsukQ59cgGY8Uaah88kjL5fx5QlZdkxUNbkDHIMQ++qS7D"
                "1nnyFUqhHlNMvSuZK1fXqRhUhap69aRhnUyKyxTMwBwswBKswBpswPbkEbJ1HEqlntKpR3SrK716R994N1"
                "DVqeeMDo7QrrukpSqSHZgDmAvzvM+v2ZzAQlgEi2EJWZsN0avrRGpFo5UcJiIGx7eiGrZDwnw0YhSkHLvi"
                "Hr+vWx0joCfCKSOyA4H7P0c+r0GXbANfz4GrrMyyqmP3wDWW4+y7l4S762X1ZcwjQBoOINXvM01OAf7nvs"
                "RQg0/rE+A09OW8FQJ4+UuJqyqznjiGunWqiav0+BQcegIjR2e5j2Vobwwvcie5j95yFcPCdxXG3bniECmQ"
                "lY+G0onLqnE5DS6v7b2gZ4mitQ7WhOJHTYxPgMEWFybAIUDx8NO8gqIS0iKSADIiogBiACALcgDyAFIs+B"
                "XiIyikKF4YBJxNgexM0bwcHj5yCokJx0MQ4KIC6SEOEmq18Mvyy89HgP8PidnpugQNSdmjaFy+GJcMSlf4"
                "Ah5oXEtksEDvXgovEdwBIgtEBviBYrA4vPyCwqLikkCkVaxstBbdr7aCAF2wB26Tv5ZdCzwhHtqe5nGikN"
                "jUSech2B6UOBAO1bDSwsivQJsoFjJWicmn36MiJaFvvWhFeqy57HUgEUphEVsjMGJDGFXREWOxEofjPCli"
                "XRRB3WS0H+AVlcX3GTyC0n0fwWGX5vsENrNk3wewWCX5XsFkFPe9gDFa1PcIekTnewLVK/nqaBW9bsWjLI"
                "Gg4ttD1jEkDgYSuSage1OPEAnn2F7zmWoV0dA4MSPis2P5kCECJk18nngCMT+BvSY+X6IJy2dgJ4kvsDYK"
                "bK/AhogntE0/QbkGlkd8kfV9QNJmsEDii63/HrQ62JBY4kVwmW0dqNorftedTLNI/9Jwq8E8SEnWrpgFdt"
                "eqYDJ9XG2eJUNcTB6su+JX1LfQZqHilGkzYd1Vb4kSByBCFgA0FcB2iABI0X4/xbtD+J1UEN+ZoPFO+YJI"
                "CNIy8z4j+rLM2wgNzLklWiwtez2+AHI+9gGEcy3MK7eJBBZKWFDOEMW8OJ6ExdjdkHZ7ZkVYil/MtBgsS0"
                "5lip5noyTbtpWVRQrGxJ5JiTGZtUBisHeMbYCvo5P+ZL0/k2J2AMUAAhxw+2E/KqzTdmtx5F8ggD9MGwHy"
                "BoDFoYHzk9QOBeIg9R3dvx6djJADLt/h1ykwhAHpAVlvgYXzrkIe4H5liJiWz9Mk3l7DHUBRmBZUMzLPfK"
                "uRMHBEiyOQJEVm/cPGYGyyDNmQSDI+F/Xbu3pUT2q9lg0b1K9Hlw7tWkI4CnCR+qdvsh4enfkaYG6Gcxjw"
                "BeAbAIBal+6LTXcrxeKEiunCi8zS+1uXOjYHoSy4EXNuXkTrLUlJoxV2bJDH6MsjMRs2G8tvlsasojT2oc"
                "V1t2yIQlPwMtICCfpWK9WZO4Gtw0u6s9hTS71G58ThjlakCzVBM+YjScM6npVwCfM87HwHH+taYCugEo46"
                "imBSKa2zVdcKK2dXdqkxv+fATPp118TM+6zLjl8d9qi/nFU+7Z33ur7XwZ49VJKIDxrDoLtnrVnJqjCtyB"
                "zUORSvqlCwuWmQ4ZFzVkjuR+3LenE5OgrwP9z1ydHwC0fDuRDNSl4Su2swM0M9LZu6qPGvbFWLJtQXztSm"
                "XWVsBMMwICeOrkmssuxQS5FuyYRyhEp4ENa2fggVisSS8hKz6+VFpnzeUf7nKpa16O6PwSSpY3rPB6lkYd"
                "mD2eiFl5fdD5UH7cvlUFsXSqADVrUGbd0qFemfJZd24YZXzPOJLiRp4+AkEPTEmBlDDhuxbsWnSyzsqWL6"
                "qhuvebv4UDyR4ktUGqSewgqsJA8zzM+034SQLE6JQnFH2WMSFWX/Vjm3ScreuSFIcjRszN+KnHQh11XZAy"
                "7epzEf3CyIdsPSF2HD2o3ZYuelKqikg6KzSHyV649Jnd4fc2iCgSBucqfLg2IO5RLfutpKusgmDxapq5HS"
                "pD5+la82KwhVyt5s5uwS6/1rNoBtgOCIzT8kbSY36KqJKcgoulfNLFTbYPoNbvKgbg96Pb2qPjH70758+m"
                "S13tbHYiV1G+/CA9mR8CT2hKIViO9KwYVq9oFYkOnvb5WViCClYQewYAHcAHH6YXP4Ijk+ZH12N/Km7AiJ"
                "1FHBY9mdPusl8p9IdsP6MMCsMwx/zB8l45BuqXt1846SoAdDZt6noTlcl7wAOl3rhrKSN9YaTvXLRN/eui"
                "WJb3YpB0vZ4tbnW4qlSBranIajAtSTVhxAq/hdmN+FKlMFOGlqAFVadqEYTaqDvZE9nAQUYO7qVTS8a8mO"
                "mOnlseQ3x4kdT8+91dHd+tu2/tUJ29qTc22ZIUENg7SkVilBZOv2wILgtKHWgTTItPVLlQuh1+Sy+qzChx"
                "FD9fhnrxrw0DcU2mORFxFYiQlKQWyur/h376Bx3LLs8I9P17x9vlyNd1J6XDfiycouNOQtAQoOWy59fnXC"
                "Df/61J4vmXjLq6odtfavXtXaKbSdd4aTgAIqHnAHTIQ4ofkJXMOCAqkmTag4Knf3pw2v8dMDVoeODFp6TL"
                "35Y3mqYjqCNszj0QZnQitpIH4SktQankeXnGkuiBgd5Jy3EUiVyAxjfS1sxBOKs3KK25KUCGRz/crlPZLh"
                "vYJb1oup/FOtyNBL0nKp/Dl3RUlet79/LX1RhiTP2sCQsSGhcy29Arez6znwSWlRdXWQ8QdGItUXZksngz"
                "k5y3J/dwIK2B+xyzHCyQA1g6ReIfVeYyPlVk9GSkZvNvlObR3lfl8e2GmoPSOszzM/vFngbjt+u+Z38MG9"
                "Ap2Tglef6yAqoK8jLFowHBs6AdwrJYx90+xUYq5JWIA8nqyrXjx3dEscaHkUFcUCCphiG23zHzbN9LwpLk"
                "CsXYxta++aqI1sotDaQcsTAAWxgAKwzVN74HVkgfX27QLHyA/ugUNYB76rmdlfQnpUVU163F+amT1QiuDq"
                "qvRvrYESWANxiACMYdHpuiI1b2SRXxRT2ozVQQtqZJZCQFGsl/aFrQFJtrSEFgb4gTubmqwkhrthdvkUDE"
                "Dd0G39rHWlgNcalyI15aPaY7LzO2II7mx6DFbM7rbppZswDNUd5xUSV2TtnoDnxZLMWBCHiA0Y67zX/ZPN"
                "T0vyRVYuxrY1dI8XkBr9Itugzc1biCVQFQnYLES4t4a/GkXrqkYeVqcMg7Upy9dLXTPKqJ46HQpDTy0LH8"
                "j8NVn9Zq59XkbaBBxn9L/d/bnnJhEIe65Gfvv6lfFtzzUCac/NyB9f7dfvZiZ85visjuTuv5MJPPjM9lsd"
                "Abd0ABQkgXiz9F1L2u/tsCR9dIXDLe32aKQzAipafZicZgqlOYZxaFbdvvPUWVzrhNREUsCd2zJH90dyZY"
                "V24EBSuU74/4CE2EQ6ksLKHPSI4o/6RpRDEIQyqleIBYtqizt7vEJKIBD8CXk1OyLDuz0YQhE6R3R8H9Kt"
                "4dgZs5ZBRAdMnH4xqI25pvpUBPZPHJSltUJdlr4dPezrQJPO/92YvZZRWVdFC0FsKBxQALj7KsedmlYkxE"
                "ajJbOPdFXyRlmMWUiAJNb8JDchBGa32RPsxBc0BuwSHNWk7d3PBQrXtKeGLY+cWnP2XgBHvEoDyLPvPS4U"
                "gqKEoP2CikHjygGj5mXxLQM85ZSJqqIrjxPAXdYioD378Fb+gtr4sAkcgBOreJ/luya88RjWPAiAFzk7Gs"
                "UjV7pExTnWAAliGfPjOwFhl7pH9pNdgAW42HEPgf19lXuBjQeRMAh5CdcO1qVtku3UOvgbBqFz9pttzbEj"
                "NjVz37qGDv9u05JN27Rel3gtf+gQ0r/xjmrSKCGsFsKAwWwao/P443RmEzAgLKxmjCjhMRhe50MthUAIIB"
                "fVe0YwGjxJRRAAgZSSBl/AXVdpACz73sPCLAWQiO+6oKrfuHrQqHlZYvMoTzljoqboypMEr5WNzDnscSJD"
                "xrB+fMXVZ+WuadxENHOOD3E7k5EdRPMdq4EQw5wdq9R9W1CgELL4WGHM5Jl54BbQL2LaE7GHr5sKyAZuzy"
                "MNvXa52B1Ay5aQ/FwIgaD6ACGBBbkQJO3MYjqKLnh2cXkQDHkkD6T0Tkz2BSVi0vPfdvSf/DNxIxk0SvfJ"
                "07AjtBzK4MmFncKZxcnwP9DO2Jyp6fnsOYj2REmMvlFa+IiHpJXFUIJbENNlK9+XTI2l+Hwa/HzwwOHnR+"
                "v8XAuK86K95grRX8+DsVzFef+URghHYhPdacGpXo5OGV4xKXtSAuJ3OOAiPSl+CVux3yA8tf4oJTtnLyW2"
                "MiAkN50rgy6WqSphR2Q0XKIAafEk7J/ayPXok7hxtnbxk2jwx3d40JHLP0JPaBSJ+OGTuMMnOJXhR0jnhN"
                "tEGcw9NnLa9vq8gvqflnKBnR9/OoTTGy1ImjzDAAe50ClcpZB8tnmPEHm/tHn+zd6N5X8/MXEe6fnjDWiD"
                "HSNEBm88mNXNjU+aOMuqOBaUxfX1TmcHOYabOvipI3ak8aBJ/RIXTT4fekn9EQ9M5SqukjKrgjjNjQI5FA"
                "eTVOZPExQd8BVmrfvyi2j+KWVsDCpxw65GVlBG1WVS2W63EG0rvOF/qfQAx3BdnIepazwx4rYf28vRgeVD"
                "IEX6ODgyvOIGraSdncJVZpPPNu0WIu+/bl55sW9j2d9PDNy2jNyJekmjQ/1ENn88mNnNTUiYPMsoP+YYYY"
                "4jWnsmc0PwEda2RAnE9gd82HsCBf8EooDkc3jWBlnrw/vnY4C1Dr8vfDfJK8qWTXyCCv6fjFjFGtaxgU1s"
                "YRs72CUVSwPWsIEt7GCXci3124AqsIZ1bGATW9jGzohuTgCE/o9XfeCd/xvTsv2BwP+TjdPeYCCk30jV4P"
                "+dKQI9GSFp3qePQUh/awUI1lFcFAHLLXuXTAHlGOgG0Dvf2Z+n5UzCSNAfIyGPN3bOeF/9PVIcRUPhSOh6"
                "tKVcGMmKsbevN84MEsu+Lhh1f59JkajfBk9pPgMnx/e3M9A+R3HUZsstexfbDgVjFwB99wTovLN9/Cs5Qs"
                "75W0d5CQC++bx7HYBvj5Kufrv/W6gSKw2ARQEQ/C8luPB4xOLz5x4A4Xiy65cCY8v0FbZNTj6fzTyZvsPJ"
                "cTqQhJBpczx5isTxnayxWPq4z1q7a22ckZ5h0QkN18ZZL/7wo5k3086aBm+t41Vjk3F6MlT14xfYPWl6PK"
                "ZImZQ9vN/1i2mTWhoZdCsfhZPOYrSub29aOZjBgjMdOd3FwDu5v+WeQSibhd5F/nrwjIrzgiDAertIu0Ci"
                "hGdoEuBzlyhJSYB7AOsm8u65KUFv3bSpD6oa426m2X52teRDKx1CDvzhCjcMb3hXkc93mQhl4aDxIBAvQ6"
                "IYUaIl0zA1DkrZzhZwsq/Dl4wj0e5uq0QCsThYTGWZlMii/6MVm0RDO4Ngdx8viaORkeNiRnefgsnMYQI8"
                "5lB4khB0MnN1w1mUHTjm247hTiAOGwVHlBRxGBJZGxqbmGeB7aj8UDlJ+U2JvzjjtmMI8GmQpO9TbmrsIF"
                "sTY7MdZeFQNhKgK5lM1STySmSEiTrO6X8Ln0n5Lv4Vj6wGAA==)}@font-face{font-family:B;src:u"
                "rl(data:font/woff2;charset-utf-8;base64,d09GMgABAAAAAAhQABAAAAAAD4gAAAf2AAEAAAAAAA"
                "AAAAAAAAAAAAAAAAAAAAAAGhYbhCocUAZgP1NUQVRIAHQRCAqPQIx0Cy4AATYCJANYBCAFg1YHIAwHG/YM"
                "UZRR0hhkPxNMlbEboUgq+fBI0pEkVMwtRsc8kTqPvob/GX6NoH7st/e+aHLMEyXSaHjI5tU7oVEJRaw0mk"
                "2nBHj/P27694UIJFCoHdq50ok6paJURELVmdGOUTWmxtTDXPn9zPxom4glMvErMJW4alpRu79ZXw6UtFRH"
                "/wP4wv6/tVZ3013cAY9nCTwkHhFCIlPKnxP7J3PoDKpJxLtGOqGIyGnDsiZIBUIhtMhTmqVhJtyMGedU9E"
                "0+RQBNABIEsYYgoG6AMbCFBeszo257Y86ocMBvxbAtP8gZBbBEOEyDoQ1DoYwEq3ZEjMdbW2SsoQwLL9Uh"
                "NpGWBcwcl5DPdS1HrnGR9VrcRDbPruGaAV4JWAbmEqeVSq7ZMHXB1nex0hbQ7QIMGoIBRSRh5+0YDIXAw8"
                "cnIpISHHITgyjoEDy8B/JkgkRVMjPzT0ne3bgMTGT5pDwUY8MWguETwiujkBoBKnOkFvhQmsKnmteaEAWY"
                "WD5Z4+HCpeXNialh5VNv+btjzhGmFhB3gDI+YIIQClkOOkqaOegsIERWDHC0nRNKUiu0EeCAkCI1SO+AE4"
                "ipIPIVYOpAkCGiaJwXSj7pfs51YvNESuDpkwVAc2RxpYRAv9NtV69OtSqVdLQhmCmgnBPDnjp9HpgAaRGY"
                "wgN4i0LEjm6MCA/yIm5l/dGcHT5ukKVUUrUMxoUUjvZBN7psscGtpPxTq/D4bFn6FhxEFz65g2XefcoU3U"
                "ZFwXAXP6GLn93jZd1/Lip6ajQyrPgy8C6k33lCWyDxCB/K0OgsTGKThMmsLuw4pBuRzJcbjRKoJz675Shy"
                "M8IaR8dbz4jdf85bnhrlYYVT2BnD0GMZQhnGvnWOjwKmaDOIpBG9neMc9Tiq4LBwHGe9E8MyOLNNYIlkcO"
                "GtW6No8Ey/60O677y3abuTVPjsnh9qqYNxJEMwSXO5Y3y/A8ZPGNPzLoAVsszIg05NKXOFnMNODMskJRfG"
                "SkdB50AuxIVJEMXSiYsB4nhFEptEs/2FwESO8kv7S4xPCzIqBnJLp3Z2bpOwu7B2Ua3WGKwZTRqj011j8o"
                "xzIpPHha8aCJpgXUCCXJmkQtrOSuUNnBlHLLWvo3k0x9g9NCkk0zPtzybSyaIkhg2a8EEKIy9UKCZclMjh"
                "OlbA8MtvYnFa4MsODySK8Cs+J/27bXBorTb80ET/gyMObQ+j6SMQO+jPoelfaJ1t0Pfuuo3f7ndInLeS5f"
                "/e3p43DwAYuRUA/r8bv0JDgd3msXUbu+/Zs1HqUNUlezKk4Zyny3aWdd133rdpN1ADRpys6J1V0ac3rwLk"
                "uWBZ/q/5YP4FReQW5ZoVseyyPFnp1YkrbU4t3p0ad1rd1MEsqTQ9mFWy9w/TDIKYfM2NRcmlT92ymiL9o9"
                "IOrAzp+Wvh//Ok/652HIRppafOjC3e/QnXwtb+G/4LL7qhyQ5o6HS/MSpYVGSpt1o1cjJ/U019feuxjYPW"
                "Pl45teicrmtG7BJDv90hCXf3fTZdE0ZFRB1Y6X2z2BCm7PS689S3R6ZNssU6V6ZqnFegC7tXBd8pYPpsU+"
                "6m0is1JwYfb/T5+LnRd+AJw6YdSs/ULT1MvH96P/7JTaWbzuh86YY6JX6mQqM+qfbBwMHQxzAKRrLPHzVA"
                "6+ITGr3STVVu89kEfHhh6rHFsGWHMuZm6QLWTN8xFsYztQYA+tU1+NJndDB+9s0ezTrVoTSZOgInXLiW+H"
                "blsZ1RA2/71lzanul/8XBcesmlwrCHafn6RPNtVZm7ZlxYcM+Vz2f2j2nV//CCO0CCCUigFsJ8pfucOUr3"
                "+RQC7BrN6y+rbh9w8aZNr5MjgA+pnKb41lw/8qQOeiyCusn8nV6YbUYnG/M1FRfyJyVLpsS/L268QoAYN+"
                "FtB9an1u04sfmNuUdWa02uW5W3V0eUAXrM1elMWi8yPvZ+qV73NjUDTl0zGfYcutAQtd3b7xCMS+9zbdJp"
                "vU+XWe9HzmsP7mfu4kAXXb1ZdbHWm9JqvQUX66uqjkD0YaeaOwW3ZwJ/1ovPPd6CDdmMgPmzpqYsXvmNZG"
                "jU/ZLCbsuRg3nnOuHoSL2bb13gJZi4AM71OPc6wgTEft8pSrc+4wbbPRt9M1FuNcf3qFy1LReWYLHF+Sgm"
                "XJL0eZ1e/Tg17fKWw2c3Ou11Vh0ANxL654L5qIFu2eck/kDEzGnuVnZTr8ptsxj/wGGxwxMGVHy/h5x5Mj"
                "w+Q9e2FPjZMIubRWZfGrtooUym+FjZQvrqYxfOA9vclhZu1qXt/P6O9b6hupPn9Ry3PTSR9fFJTycGEECh"
                "+PB3s7bZUzztizLMAOD746FhAH7kq37/J79VI7EQgDIMIMA/MRs9B/Xnz5P/q/nfq5t9V8A9xYfvchFqyH"
                "GgJjnNkZI9UA3AdFqI3+6QckegVpOREqmoyd0+3E61AmyUfZtlfcBL/bB44l2MhC8goGcTCEWSQ2KJ31aX"
                "ioeKAgC3AA8DQlMbMBa0Bh6ZFgOumzsGwgQf9aRuMSQFEoMw5hgkQMcKlLoLda5C6QNEAiFEjCE7ij7WNW"
                "Rv4GI55AEQq4C8PeZxhGK2B7FQUwAKOMSBQCUTC6OrsgDRIJW02jp85uWZrlBkKHiDHM/Xg/zFI0/gIWUB"
                "Q6PIOJhsqjVONk6WsEh7Pr4zO4JXtRkVKeSIU0uSok0mEmMOtIMT+OlRClJ9471uzlPTJCrkYX7/PQbo/I"
                "z+3axYAg==)}text,tspan{dominant-baseline:central}.a{font-family:A;letter-spacing:-"
                ".05em}.b{font-family:B}.c{font-size:16px}.d{font-size:12px}.f{fill:#",
                uint256((_colors >> 72) & 0xFFFFFF).toHexStringNoPrefix(3), // Fill
                "}.h{fill:#",
                uint256((_colors >> 24) & 0xFFFFFF).toHexStringNoPrefix(3), // Primary text
                "}.i{fill:#",
                uint256(_colors & 0xFFFFFF).toHexStringNoPrefix(3), // Secondary text
                "}.j{fill:none;stroke-linejoin:round;stroke-linecap:round;stroke:#",
                uint256(_colors & 0xFFFFFF).toHexStringNoPrefix(3) // Secondary text
            );
        }
        {
            image = string.concat(
                image,
                '}.x{width:1px;height:1px}</style><mask id="m"><rect width="20" height="20" rx="0.3'
                '70370" fill="#FFF"/></mask><path d="M0 0h550v550H0z" fill="#',
                uint256((_colors >> 96) & 0xFFFFFF).toHexStringNoPrefix(3), // Background
                '"/><rect x="143" y="69" width="264" height="412" rx="8" fill="#',
                uint256((_colors >> 48) & 0xFFFFFF).toHexStringNoPrefix(3), // Border
                '"/><rect class="f" x="147" y="73" width="256" height="404" rx="4"/>',
                _drawStars(_phase, _colors)
            );
        }
        {
            image = string.concat(
                image,
                '<text class="a h" x="163" y="101" font-size="20">Puzzle #',
                (_tokenId >> 128).toString(),
                '</text><text x="163" y="121"><tspan class="b d i">Created by </tspan><tspan class='
                '"a d h">'
            );
        }
        {
            uint256 luma =
                ((_colors >> 88) & 0xFF) + ((_colors >> 80) & 0xFF) + ((_colors >> 72) & 0xFF);
            image = string.concat(
                image,
                _formatValueAsAddress(uint160(_author) >> 132), // Authors
                '</tspan></text><rect x="163" y="137" width="224" height="224" fill="rgba(',
                luma < ((255 * 3) >> 1) ? "255,255,255" : "0,0,0", // Background behind the heatmap
                ',0.2)" rx="8"/>',
                _drawDrunkenBishop(_solveMetadata, _tokenId),
                '<path class="j" d="M176.988 387.483A4.992 4.992 0 0 0 173 385.5a4.992 4.992 0 0 0-'
                "3.988 1.983m7.975 0a6 6 0 1 0-7.975 0m7.975 0A5.977 5.977 0 0 1 173 389a5.977 5.97"
                '7 0 0 1-3.988-1.517M175 381.5a2 2 0 1 1-4 0 2 2 0 0 1 4 0z"/><text class="a c h" x'
                '="187" y="383">',
                _formatValueAsAddress(_solveMetadata >> 28), // Captured by
                '</text><text class="b d i" x="187" y="403">Captured by</text><path class="j" d="m2'
                "85.5 380 2 1.5-2 1.5m3 0h2m-6 5.5h9a1.5 1.5 0 0 0 1.5-1.5v-8a1.5 1.5 0 0 0-1.5-1.5"
                'h-9a1.5 1.5 0 0 0-1.5 1.5v8a1.5 1.5 0 0 0 1.5 1.5z"/><text class="a c h" x="303" y'
                '="383">',
                _formatValueAsAddress(_solveMetadata & 0xFFFFFFF), // Solution
                '</text><text class="b d i" x="303" y="403">Solution</text><path class="j" d="M176 '
                "437.5h-6m6 0a2 2 0 0 1 2 2h-10a2 2 0 0 1 2-2m6 0v-2.25a.75.75 0 0 0-.75-.75h-.58m-"
                "4.67 3v-2.25a.75.75 0 0 1 .75-.75h.581m3.338 0h-3.338m3.338 0a4.97 4.97 0 0 1-.654"
                "-2.115m-2.684 2.115a4.97 4.97 0 0 0 .654-2.115m-3.485-4.561c-.655.095-1.303.211-1."
                "944.347a4.002 4.002 0 0 0 3.597 3.314m-1.653-3.661V428a4.49 4.49 0 0 0 1.653 3.485"
                "m-1.653-3.661v-1.01a32.226 32.226 0 0 1 4.5-.314c1.527 0 3.03.107 4.5.313v1.011m-7"
                ".347 3.661a4.484 4.484 0 0 0 1.832.9m5.515-4.561V428a4.49 4.49 0 0 1-1.653 3.485m1"
                ".653-3.661a30.88 30.88 0 0 1 1.944.347 4.002 4.002 0 0 1-3.597 3.314m0 0a4.484 4.4"
                '84 0 0 1-1.832.9m0 0a4.515 4.515 0 0 1-2.03 0"/><text><tspan class="a c h" x="187"'
                ' y="433">'
            );
        }
        {
            image = string.concat(
                image,
                uint256(uint128(_tokenId)).toString(), // Rank
                ' </tspan><tspan class="a d i" y="435">/ ',
                uint256(_solves).toString(), // Solvers
                '</tspan></text><text class="b d i" x="187" y="453">Rank</text><path class="j" d="M'
                '289 429v4h3m3 0a6 6 0 1 1-12 0 6 6 0 0 1 12 0z"/><text class="a c h" x="303" y="43'
                '3">',
                _formatTime(_solveTime), // Solve time
                '</text><text class="b d i" x="303" y="453">Solve time</text></svg>'
            );
        }

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"',
                    _puzzleData.puzzle.name(),
                    ": Flag #",
                    uint256(uint128(_tokenId)).toString(),
                    '","description":"This token represents solve #',
                    uint256(uint128(_tokenId)).toString(),
                    " in puzzle #",
                    uint256(_tokenId >> 128).toString(),
                    '.","image_data": "data:image/svg+xml;base64,',
                    Base64.encode(abi.encodePacked(image)),
                    '","attributes":',
                    attributes,
                    "}"
                )
            )
        );
    }

    /// @notice Returns the SVG component for the ``heatmap'' generated by
    /// applying the Drunken Bishop algorithm.
    /// @param _solveMetadata A bitpacked `uint56` containing metadata of the
    /// solver and solution.
    /// @param _tokenId The token ID of the Flag.
    /// @return string memory The SVG for the heatmap.
    function _drawDrunkenBishop(uint56 _solveMetadata, uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(_tokenId, _solveMetadata)));
        // Select the colormap.
        bytes8 colormapHash = [
            bytes8(0xfd29b65966772202),
            bytes8(0x850ce48e7291439b),
            bytes8(0x4f5e8ea8862eff31),
            bytes8(0xf2e92189cb6903b9),
            bytes8(0xa33e6c7c5627ecab),
            bytes8(0xaa84b30df806b46f),
            bytes8(0x864a6ee98b9b21ac),
            bytes8(0xfd60cd3811f00281),
            bytes8(0xa8309447f8bd3b5e),
            bytes8(0x3be719b0c3427972),
            bytes8(0xca0da6b6309ed211),
            bytes8(0x5ccb29670bb9de0e),
            bytes8(0x3de8f27f386dab3d),
            bytes8(0x026736ef8439ebcf),
            bytes8(0xc1806ea961848ac0),
            bytes8(0x87970b686eb72675),
            bytes8(0xaa6277ab923279cf),
            bytes8(0xdc1cecffc00e2f31)
        ][seed % 18];

        // We start at the middle of the board.
        uint256 index = 210;
        uint256 max = 1;
        uint8[] memory counts = new uint8[](400);
        counts[index] = 1;

        // Apply Drunken Bishop algorithm.
        unchecked {
            while (seed != 0) {
                (uint256 x, uint256 y) = (index % 20, index / 20);

                assembly {
                    // Read down/up
                    switch and(shr(1, seed), 1)
                    // Up case
                    case 0 { index := add(index, mul(20, iszero(eq(y, 19)))) }
                    // Down case
                    default { index := sub(index, mul(20, iszero(eq(y, 0)))) }

                    // Read left/right
                    switch and(seed, 1)
                    // Left case
                    case 0 { index := add(index, iszero(eq(x, 19))) }
                    // Right case
                    default { index := sub(index, iszero(eq(y, 0))) }
                }
                if (++counts[index] > max) max = counts[index];
                seed >>= 2;
            }
        }

        // Draw heatmap from counts.
        string memory image = '<g transform="translate(167 141) scale(10.8)" mask="url(#m)">';
        unchecked {
            for (uint256 i; i < 400; ++i) {
                image = string.concat(
                    image,
                    '<rect class="x" x="',
                    (i % 20).toString(),
                    '" y="',
                    (i / 20).toString(),
                    '" fill="#',
                    colormapRegistry.getValueAsHexString(
                        colormapHash, uint8((uint256(counts[i]) * 255) / max)
                    ),
                    '"/>'
                );
            }
        }

        return string.concat(image, "</g>");
    }

    /// @notice Returns the SVG component for the stars corresponding to the
    /// phase, including the background pill.
    /// @dev Phase 0 = 3 stars; Phase 1 = 2 stars; Phase 2 = 1 star. Also, note
    /// that the SVGs are returned positioned relative to the whole SVG for the
    /// Flag.
    /// @param _phase The phase of the solve.
    /// @param _colors The colors of the Flag.
    /// @return string memory The SVG for the stars.
    function _drawStars(uint8 _phase, uint128 _colors) internal pure returns (string memory) {
        // This will never underflow because `_phase` is always in the range
        // [0, 4].
        unchecked {
            uint256 width = ((4 - _phase) << 4);

            return string.concat(
                '<rect class="h" x="',
                (383 - width).toString(),
                '" y="97" width="',
                width.toString(),
                '" height="24" rx="12"/><path id="s" fill="#',
                uint256((_colors >> 72) & 0xFFFFFF).toHexStringNoPrefix(3),
                '" d="M366.192 103.14c.299-.718 1.317-.718 1.616 '
                "0l1.388 3.338 3.603.289c.776.062 1.09 1.03.499 1.536l-2.745 2.352.838 3.515c.181.7"
                "57-.642 1.355-1.306.95L367 113.236l-3.085 1.884c-.664.405-1.487-.193-1.306-.95l.83"
                '8-3.515-2.745-2.352c-.591-.506-.277-1.474.5-1.536l3.602-.289 1.388-3.337z"/>',
                _phase < 2 ? '<use href="#s" x="-16" />' : "",
                _phase < 1 ? '<use href="#s" x="-32" />' : ""
            );
        }
    }

    /// @notice Helper function to format the last 28 bits of a value as a
    /// hexstring of length 7. If the value is less than 24 bits, it is padded
    /// with leading zeros.
    /// @param _value The value to format.
    /// @return string memory The formatted string.
    function _formatValueAsAddress(uint256 _value) internal pure returns (string memory) {
        return string.concat(
            string(abi.encodePacked(bytes32("0123456789ABCDEF")[(_value >> 24) & 0xF])),
            (_value & 0xFFFFFF).toHexStringNoPrefix(3).toCase(true)
        );
    }

    /// @notice Helper function to format seconds into a length string. In order
    /// to fit the solve time in the card, we format it as follows:
    ///     * 0:00:00 to 95:59:59
    ///     * 96 hours to 983 hours
    ///     * 41 days to 729 days
    ///     * 2 years onwards
    /// @param _solveTime The solve time in seconds.
    /// @return string memory The formatted string.
    function _formatTime(uint40 _solveTime) internal pure returns (string memory) {
        if (_solveTime < 96 hours) {
            uint256 numHours = _solveTime / (1 hours);
            uint256 numMinutes = (_solveTime % (1 hours)) / (1 minutes);
            uint256 numSeconds = _solveTime % (1 minutes);

            return string.concat(
                _zeroPadOne(numHours), ":", _zeroPadOne(numMinutes), ":", _zeroPadOne(numSeconds)
            );
        } else if (_solveTime < 41 days) {
            return string.concat(uint256(_solveTime / (1 hours)).toString(), " hours");
        } else if (_solveTime < 730 days) {
            return string.concat(uint256(_solveTime / (1 days)).toString(), " days");
        }
        return string.concat(uint256(_solveTime / (365 days)).toString(), " years");
    }

    /// @notice Helper function to zero pad a number by 1 if it is less than 10.
    /// @param _value The number to zero pad.
    /// @return string memory The zero padded string.
    function _zeroPadOne(uint256 _value) internal pure returns (string memory) {
        if (_value < 10) {
            return string.concat("0", _value.toString());
        }
        return _value.toString();
    }
}
