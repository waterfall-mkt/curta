// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Base64 } from "solady/utils/Base64.sol";
import { LibString } from "solady/utils/LibString.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";

import { ICurta } from "@/contracts/interfaces/ICurta.sol";

/// @title The Authorship Token ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice ``Authorship Tokens'' are ERC-721 tokens that are required to add
/// puzzles to Curta. Each Authorship Token may be used like a ticket once.
/// After an Authorship Token has been used to add a puzzle, it can never be
/// used again to add another puzzle. As soon as a puzzle has been deployed and
/// added to Curta, anyone may attempt to solve it.
/// @dev Other than the initial distribution, the only way to obtain an
/// Authorship Token will be to be the first solver to any puzzle on Curta.
contract AuthorshipToken is ERC721, Owned {
    using LibString for uint256;

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when there are no tokens available to claim.
    error NoTokensAvailable();

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @notice The Curta / Flags contract.
    address public immutable curta;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 public immutable issueLength;

    /// @notice The timestamp of when the contract was deployed.
    uint256 public immutable deployTimestamp;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The number of tokens that have been claimed by the owner.
    uint256 public numClaimedByOwner;

    /// @notice The total supply of tokens.
    uint256 public totalSupply;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _curta The Curta / Flags contract.
    /// @param _issueLength The number of seconds until an additional token is
    /// made available for minting by the author.
    /// @param _authors The list of authors in the initial batch.
    constructor(address _curta, uint256 _issueLength, address[] memory _authors)
        ERC721("Authorship Token", "AUTH")
        Owned(tx.origin)
    {
        curta = _curta;
        issueLength = _issueLength;
        deployTimestamp = block.timestamp;

        // Mint tokens to the initial batch of authors.
        uint256 length = _authors.length;
        for (uint256 i; i < length;) {
            _mint(_authors[i], i + 1);
            unchecked {
                ++i;
            }
        }
        totalSupply = length;
    }

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a token to `_to`.
    /// @dev Only the Curta contract can call this function.
    /// @param _to The address to mint the token to.
    function curtaMint(address _to) external {
        // Revert if the sender is not the Curta contract.
        if (msg.sender != curta) revert Unauthorized();

        unchecked {
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    /// @notice Mints a token to `_to`.
    /// @dev Only the owner can call this function. The owner may claim a token
    /// every `issueLength` seconds.
    /// @param _to The address to mint the token to.
    function ownerMint(address _to) external onlyOwner {
        unchecked {
            uint256 numIssued = (block.timestamp - deployTimestamp) / issueLength;
            uint256 numMintable = numIssued - numClaimedByOwner++;

            // Revert if no tokens are available to mint.
            if (numMintable == 0) revert NoTokensAvailable();

            // Mint token
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _tokenId The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_ownerOf[_tokenId] != address(0), "NOT_MINTED");

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"Authorship Token #',
                    _tokenId.toString(),
                    '","description":"This token allows 1 puzzle to be added to Curta. Once it has '
                    'been used, it can never be used again.","image_data":"data:image/svg+xml;base6'
                    "4,",
                    Base64.encode(
                        abi.encodePacked(
                            '<svg width="750" height="750" xmlns="http://www.w3.org/2000/svg" fill='
                            '"none" viewBox="0 0 750 750"><style>.a{filter:url(#c)drop-shadow(0 0 2'
                            "px #007fff);fill:#fff;width:4px}.b{filter:drop-shadow(0 0 .5px #007fff"
                            ");fill:#000;width:3px}.c{height:13px}.d{height:6px}.e{height:4px}.f{he"
                            "ight:12px}.g{height:5px}.h{height:3px}.i{width:320px;height:620px}.j{c"
                            "x:375px;r:20px}.k{stroke:#27303d}.l{fill:#000}.n{fill:#0d1017}.o{strok"
                            'e-width:2px}@font-face{font-family:"A";src:url(data:font/woff2;charset'
                            "=utf-8;base64,d09GMgABAAAAABFIAA8AAAAAIkwAABDvAAEAAAAAAAAAAAAAAAAAAAAA"
                            "AAAAAAAAHIFYBmAAPAiBCgmXYhEICp9Am3cLQgABNgIkA0IEIAWDTAcgDIExGzcfE24MPW"
                            "wcDIypV8n+6wPbWHpYvwUfDDXpJJFBslTuUGiwURSfehX/e+bvN6mwulNEycH87rF0PSHI"
                            "FQ6frhshySw8/9Scf9/MJISZENRCTVFJ1cErnlKV3fCVijl22lBTW3X3ffk7sF1tDOFpz3"
                            "ulSlfAabKmnF0P4oO2fq29SR7sfaASK3SVZcuSrsSqs2ba0noIACigkR+0RR3auT4I9sP0"
                            "SVMG/h9t36wowdPc8MB/BrGVwfJtxfAEzawVNUU9XXUyuP84V72fJk1TzgBQZhYxC9gekU"
                            "Nhz5h1atzZDSj//9es7H0/lQGuGT4e6XiUalRBoP6vADYkPQw1aeL0ALMknWQQFKMiVrss"
                            "zLp1cq3f5XA2MbxTH7ZlmG9qAh5RGLTi3/buX4sAOtmYKD17DyzGNX3c/JkkoAFYFiqgoL"
                            "lcoKwN+8SZs2bQJpy/039f0IT07mYumDGX3OkeQKhtalzAJiHFqmDHRepg85j2HtMhYXoI"
                            "Qja+acMcHkFiWRYc64dhBHE74RiyoF9YUybKGmygLFPKgQE3mWU0qdIeFGz+mufSyI0eTo"
                            "/ebjdXaEmONvbHdNDGSrUbWQ8gfyoXADcUpJDKwxZTQlmjHdljgkI92rIAkHysWd+tiwiI"
                            "D5Xor0lTmjPIn2Bl2xlLdc/6xALygxzlIHIGSp5aRIVlzTcyxsJaE5QLskMtpMy7JpvuPj"
                            "Uo2MWFiwACT2mape1/WBm2jfvwKbF3yOytnKr/kmDe/ffSHOMjO3TegzdAmwwQWGKAQK+c"
                            "Bhh0LF7h+dMwkwVOj6a4TfI4nt98Vtdg3vXfxfuD5LHZiSN72tFbVsUc3R0zeztLSohtiS"
                            "0svM6iU/Uv3Qmfl4/otQv/jh3g4A0oOWcHRc4GbtNJzgEHmgru3bEQPEgIi7gWnfcZKgEO"
                            "8+Z1XMUoKtO09Tjp2lUOvJjROEPveThU3/tfL0bd6jo8v07lwHVvcrLss7BvExTOLIdsVZ"
                            "QXQPLOgBZIcA2J124CFjvY6BQaQwUxDEhIzTQBj/7xNBKgmC25O1wmzuk8DHIxcRpve9ih"
                            "ai6Dx+eQS2Guk8G9aNoPq46hCuEQzpn0DrEA5cNx6ybsFycgDTIqICT1EGrGPKQhWGg3yT"
                            "vz+bYPRKis1fC3mwRiQEUi5Jar7lMsZqIS3VOUGEgg0ul47PrH07gfVmIW9T9FbNECKbbf"
                            "pconk3yVaGo/Ahrbr9P224ag88ZW7LKAitUe741kKQXVSBLZmCnMYw0TiopBOyYcr0WduE"
                            "S4x/5FIgsNvUH1weP6wNRJz2bNhJwTgeqoZZ7qMnvnrUhnbAIRXAwkkj7vIhYqrV7vEolF"
                            "TQks4hu8RBWo/k7XFtMKN7H/WQszwb877koOlFCxeSdgNLsxYo4J88ywwByLLLDEEsusYI"
                            "U1WGWdETtghEGeEbdsv0umBvraHesHFh31K9LvwKb+RPo7pjtYICDGRl1S6pFSn5QGpDQk"
                            "pREpjUlpQkpTUpqRjl1C7RrFylpIi8Z2N8fzOIYKy236t9kAq2A1DGxCmmsBx1i3Ys+Gde"
                            "8VbuTYckbHpx02h1XI9jTdy8b5t0FJ3jV2B3qsK99NWYU0AuJQCE7aNgY7v4D+PpPntlJ3"
                            "ZPt2YA9qNdc1B5B+QYF9NBfawMGwAORUY4sforK0c02NigE7EJM2+5e5DbfaKR06nyGLw4"
                            "HI9tnbgSOAHbjDvTs1indO+g2T2v7IN9BxRA39GLhFjJj4+TxR3L5OP9np8qlbpuTlgxyf"
                            "O6d6VD/EzLFZoYVyD4ry/OV4qUjBWI4Nh90xqbdg54Qoz1214l9VZxI826xbcYbHGcxXXc"
                            "IqizxhNjenKLAfXHiH4BiD59GYroC6eA6eHavJMXIrTsbfkyREzrF25c922geeRUkzTZC2"
                            "UOKsTVfeCebp8JgateYdrGE9IaY76Ppjgc0XcccsJd28zkURtobF+UkH2pkp9UZ75dR3ze"
                            "OUC5gawFLO3iS1uakbsnXnr/7lIAcLsZjJ+w99NeIoGM56PeI4+t5HWymr6o9cC5wNG3H+"
                            "m82F7F5/o0ytyLvC6ti+HVWv43Ed/ifmG09TXXtu2b+1FeeXOuqzfuJuIlxjZ/dRb/5KbM"
                            "VcevBs78zQgCNonHE12BsOzeOkp1GF3ILsi9HPIw5XZKfCztTUaNYPK0ShfLQWg2Sn5c1o"
                            "yAroqWgwEwxpJNBQJhgmQy8azgQjGglUzAQlMnSjUiYoayRQORNUyNCDKpmgqpFAI5lglA"
                            "y9aTQTjGkk0FgmGCdDdxrPBBMaCTSRycRJnXy5UywmPwr6CrXNS0WYEiLCJg+q/XmYmCrl"
                            "YZqUZ053yIMZ/vwCM6V8zJLyMVvKx5z6BZgrFWCeVID5UkGhBZ2O+2vKmy6je13YMcmnth"
                            "q6+PUkQ2cEsSwCQY3cNPAwuRWoToMjDRmK4jL2YEBFAq9ic5UWqbQsykJncsHOgA6dDFtq"
                            "+4iQ5CAXnilOc7mczhZuw5YU5wxKOBW47qqa18byl2C+0Je9kpLlr0VqXl27py+7c+UFmC"
                            "9DuGxcFLhwtksTbHq5LlWGZuCUWZNSNub56z6vhzc8dklVXP+K19zMp2Gw+AWepkrKxCkB"
                            "FNMmnkhS+mIiBmbzxbsYu3/5uNB70qcZioGOLk4pwVD1KjUAJ8b2o+fvE7IX0jP+UvmvC/"
                            "9zTtTVhXlrXunL7lzwgXH0NT5eVVdNlAt0UumDdTUSxgQwsa7JiHLbdx+N9YpznKAMNccv"
                            "n28rh84dOcYAj1WJhyfD9DWdacXBsxebjfKUwmfoQg8iRlXZ6fEy4xAa0pv0GejZgi9HNl"
                            "+VPZ+h5aQJoqNPjcVobNAYnVcai9d8oi97lmY8z5j8lOLljWQ0fIrVgVlfWtNoRtVj1tWJ"
                            "DV7Ri/UyugbiLSQ1l7NObx9m6qcSJ+t3Yl5J34KxaVImS1+88EXY68CjXjQW5jQmulLBDC"
                            "g8RvQxjvrMq5i5pxp2kde0xy/bEDZNyghjc2O/U2E8VH9dXPONMSjesGUhiseWie5ddqqh"
                            "QfPLSl3F46EWs64VBy/C8LoTXXhrtPOXPXi8rEaJvqHu5b0Giy5whUeCM2teY23Nxvnzp8"
                            "m1O1bUrN2vYO2K/54OGzrbuyY5dHDt43aqy7UiJ3mN9zPjCpMFbBf7/IwolBQHNYAMMEi2"
                            "eOax5Af+SYKk5Ftty4uNXpQhSvBSk+NwwKH6VqiSnNnJWieKCDxBEZkKR5BPuicuUQmnFt"
                            "ZVM3IDfJHhfP2bzKbHE6ExyVcGyDdWqYxjDWwRi8A6SdIPtzB7tiQsWOxEcCciH3XnqlQ0"
                            "dFMTH4SkRDvCZLv3v6pKrhriHBLZFMOC/hyD9ElxDduSi35Bk7+sFiGpgpnuNBRGBd6gSL"
                            "mfVrbkv9wY10nPyEpPUJ4ZQA2VAEFUTLSAppnkp+575H1YSnKMePiKalkZ1NtrNCNp/NVu"
                            "Jw4FSl2hQV5RYKBXFOqQOrH/T2W+sGC3CEVdvBviVPTZZumyrT4JJOk5c5lYPL2+VUgVec"
                            "/vOTZm95Ve8r1Dspn8dClc+6DoO3+tc4xQSTC5uJeEkSpI6rG+HgaV9H5K5kFKQfj6VDYK"
                            "jGns9YnhSohHfjraDQ17bfVIIZUw8pKLa+qQEOmMsoBgd0QUiHJHBAOLMyqyc0ZIUhgKsM"
                            "Tg0NDEYAygSWEx804b0aBKnqbSZbQa03i73BmsmMQdGuwVm0xT8dAgiQv7Y5F6X6M9IgxD"
                            "m6j98u1+cbdtM6ZKxNMOn803a3lsaXGvql6xvWpia6pQPWqUcmJ0Vf2N9J35T2/D0Aq9X9"
                            "/LiNn0JZMYcyJK6HMiGXvW697jX0wUEYjticR2LoIQlZ6+1I2WZRL0qvgQc+804puiH+Rh"
                            "XP3n178mUvxMxuoYGIfVlRgzue0ARYr9NLcGAD2Vl5jGAROR3cVwvUD6Q6Ep0iFtCjJOZI"
                            "yKZAwPYx6mbEjYPWGXElHi/Vs3qPtvkD4H6C+zF15Ahg0FHXTyC1qDA+f1H7kBBjiGM+fF"
                            "M4pJhNeMcH8p7KHTfHQ5SBjIUlxTGYZ01BVqq3QFGm2KOieINiqSMSr86jn1ur37gDd/Si"
                            "+6sw1nXmDQnebqnfZNiSkbw3IOuCISSLdrnxIkfdu379sy4ZNmTychwnWgX9ewkKsoE/pz"
                            "6N6QkL2hztbp5fhDpt8flVD9cML/Ozd7gN1lD7QH2YPtIfZQexgLv0pQLe5ZGLcxhqeWlf"
                            "uo4AGTtzAGmPqke7wB+CPw7rP5phD/4Jp/h+u0/7/3F55NOEIenxjDI5A4wKXER8gNypPh"
                            "7mw0qFXibtIdD6ScM3YFwUCrAKVFNJ+5ITNvUV/gOcCJ/kQXtJZy0VgDo1NeIe0RY+uZoD"
                            "taIIocaM+8dXFDu3LB2AuHFF3gBZqRHhUpTFe+A6SFnM+wwSW04ZCm7MiidXk+1EVPLlEL"
                            "Y/hGQkhQYo5RJS0u0QDUeCwoUVz3d51KuWyyNeO73UI02URWpMMm1LxDOuEvYoylo8WlV6"
                            "lv8Lzp2XAOb1Bk5ZOsenamH1YDUthuPyzPR7q/Nl+uGHvnMSCEKixZKLwsClU+AW6h9Uwx"
                            "c5zXtGgPZKTNLxYXmDFrPx+UBz64p2oHMlG8QFT8ZHKB8lpE6sh5Y29HLcPAzXnh0WFy+8"
                            "QGHyHXM0kJj3YCbvJudjuZcNbbvrl6c5y5dbl9Ua9gUzaUnDH2DmZJluoxBAUqD0XRp4LT"
                            "1zOAwXVS9SFma9Z3Ow4MZH0JNLw7mOOIMfkcd+UerSqKWJpkvnQbocRNTTvtzMLfyfKSbV"
                            "zo+oftgP9JojCaNGPqtd8m9mu0oWybrQ62kidABygizeao16mU4mbSZFD5szXxu+2seN+f"
                            "N/C+ONDR3z0QSXu1xac4z0BPi0WqXTHQiS23iyR6LYtzKOO/CNG8c2Tr7t/tAoYM/Z0syB"
                            "80Rt//4bDt0xNOjWYyQczsMZTVX4lnibna/u9fw48fNgFIpNOyOCrpgaeOILkARCV5DiXe"
                            "8EXPWQ4OdEcIGO720kah2SLjqQvJDI/8QxCp+ISkGFe3R3nHBbjptZqOhlrLslxLBpmZyk"
                            "E4K2xIxAgAq+1G6J+KTlnejgNaJrWm7SmaNFuPJgOlFoxtKbSLWA4OaExq19dlBwsGPkHR"
                            "rXTs0O0Q9rou9s3+eNiZd+dpjFVpKzWjZGOGhaCjqkKgBz9VUzEKPhhjXewSzahn/t/pS9"
                            "uHUpZUqS1MbX6NCCB0X3Go/OuYwPz/mlj1O8Dz6R9eAbxMJbdG+3Ffma11B/xRABD44auE"
                            "MhHN+jezsRbExZke8snDQxEpdF/kvhRZe3OPpzwY5Hs8Eh/s5PWHI4CbKdiZgw2FLhSyCG"
                            "gwvqEigB+Vd+U1f2A0EHYUwhjdUcHF3I4q2ZgdNVpxpqON+XxIb6eFDKUHs5jNkqLJ1XiZ"
                            "EkrvJpVkUsjETR/FZ7nk6Uzquh8zmUAX3u1D0/3DKcx5JT5pmzyJuSxUfGJS4ghmM44JlL"
                            "mDmEViFoaazhcgH5fEU7iZLKtkHiUMoIzBh5vGHSyks52c68LcoVmqR3we1X0LuuWsP5QR"
                            "NUrjU+r4fCbg+ReG8S5kh4kzGMc0JvXzyQ7rdKoZTypQxuRM0khPXNJMrcMqaFitk6QCwo"
                            "kHnOHO8PJmkVUVPvmKMvPsZvy6nwRaaHR4OKlH7ymZ9va2cIfmqPTXi0I1WUm0n83ofjHY"
                            "E3BFN20mGv4SgQMAJiae1Co9m1tJ7bByn6e2vMVE1maWcw4T0arYhOLybl7RX6FH70WOrZ"
                            'MW6dCcHc6I9atPW9msuGc/bptop2dPAAA=)}</style><defs><radialGradient id="'
                            'b"><stop stop-color="#007FFF"/><stop offset="100%" stop-opacity="0"/><'
                            '/radialGradient><filter id="c"><feGaussianBlur stdDeviation="8" in="So'
                            'urceGraphic" result="offset-blur"/><feComposite operator="out" in="Sou'
                            'rceGraphic" in2="offset-blur" result="inverse"/><feFlood flood-color="'
                            '#007FFF" flood-opacity=".95" result="color"/><feComposite operator="in'
                            '" in="color" in2="inverse" result="shadow"/><feComposite in="shadow" i'
                            'n2="SourceGraphic"/><feComposite operator="atop" in="shadow" in2="Sour'
                            'ceGraphic"/></filter><mask id="a"><path fill="#000" d="M0 0h750v750H0z'
                            '"/><rect class="i" x="215" y="65" rx="20" fill="#FFF"/><circle class="'
                            'j l" cy="65"/><circle class="j l" cy="685"/></mask></defs><path fill="'
                            '#10131C" d="M0 0h750v750H0z"/><rect class="i n" x="215" y="65" mask="u'
                            'rl(#a)" rx="20"/><circle mask="url(#a)" fill="url(#b)" cx="375" cy="38'
                            '1" r="180"/><circle class="j k n" cy="125"/><g transform="translate(35'
                            '9 110)"><circle class="n" cy="16" cx="16" r="16"/><rect class="a c" x='
                            '"8" y="7" rx="2"/><rect class="b f" x="8.5" y="7.5" rx="1.5"/><rect cl'
                            'ass="a e" x="8" y="21" rx="2"/><rect class="b h" x="8.5" y="21.5" rx="'
                            '1.5"/><rect class="a d" x="14" y="7" rx="2"/><rect class="b g" x="14.5'
                            '" y="7.5" rx="1.5"/><rect class="a e" x="14" y="14" rx="2"/><rect clas'
                            's="b h" x="14.5" y="14.5" rx="1.5"/><rect class="a d" x="14" y="19" rx'
                            '="2"/><rect class="b g" x="14.5" y="19.5" rx="1.5"/><rect class="a c" '
                            'x="20" y="12" rx="2"/><rect class="b f" x="20.5" y="12.5" rx="1.5"/><r'
                            'ect class="a e" x="20" y="7" rx="2"/><rect class="b h" x="20.5" y="7.5'
                            '" rx="1.5"/></g><path d="M338.814 168.856c-.373 0-.718-.063-1.037-.191'
                            "a2.829 2.829 0 0 1-.878-.606 2.828 2.828 0 0 1-.606-.878 2.767 2.767 0"
                            " 0 1-.193-1.037v-.336c0-.372.064-.723.192-1.053.138-.319.34-.611.606-."
                            "877a2.59 2.59 0 0 1 .878-.59 2.58 2.58 0 0 1 1.038-.208h4.26c.245 0 .4"
                            "8.032.703.096.212.053.425.143.638.27.223.118.415.256.574.416.16.16.304"
                            ".345.431.558.043.064.07.133.08.208a.301.301 0 0 1-.016.095.346.346 0 0"
                            " 1-.175.256.42.42 0 0 1-.32.032.333.333 0 0 1-.239-.192 3.016 3.016 0 "
                            "0 0-.303-.399 2.614 2.614 0 0 0-.415-.303 1.935 1.935 0 0 0-.463-.191 "
                            "1.536 1.536 0 0 0-.495-.048c-.712 0-1.42-.006-2.122-.016-.713 0-1.425."
                            "005-2.138.016-.266 0-.51.042-.734.127-.234.096-.442.24-.623.431a1.988 "
                            "1.988 0 0 0-.43.623 1.961 1.961 0 0 0-.144.75v.335a1.844 1.844 0 0 0 ."
                            "574 1.356 1.844 1.844 0 0 0 1.356.574h4.261c.17 0 .33-.015.48-.047a2.0"
                            "2 2.02 0 0 0 .446-.192c.149-.074.282-.165.399-.271.106-.107.207-.229.3"
                            "03-.367a.438.438 0 0 1 .255-.144c.096-.01.187.01.272.064a.35.35 0 0 1 "
                            ".16.24.306.306 0 0 1-.033.27 2.653 2.653 0 0 1-.43.527c-.16.139-.346.2"
                            "66-.559.383-.213.117-.42.197-.622.24-.213.053-.436.08-.67.08h-4.262Zm1"
                            "7.553 0c-.713 0-1.324-.266-1.835-.797a2.69 2.69 0 0 1-.766-1.931v-2.66"
                            "5c0-.117.037-.213.112-.287a.37.37 0 0 1 .27-.112c.118 0 .214.037.288.1"
                            "12a.39.39 0 0 1 .112.287v2.664c0 .533.18.99.542 1.373a1.71 1.71 0 0 0 "
                            "1.293.559h3.878c.51 0 .941-.187 1.292-.559a1.93 1.93 0 0 0 .543-1.372v"
                            "-2.665a.39.39 0 0 1 .111-.287.389.389 0 0 1 .288-.112.37.37 0 0 1 .271"
                            ".112.39.39 0 0 1 .112.287v2.664c0 .756-.256 1.4-.766 1.932-.51.531-1.1"
                            "28.797-1.851.797h-3.894Zm23.824-.718a.456.456 0 0 1 .16.192c.01.042.01"
                            "6.09.016.143a.47.47 0 0 1-.016.112.355.355 0 0 1-.143.208.423.423 0 0 "
                            "1-.24.063h-.048a.141.141 0 0 1-.064-.016c-.02 0-.037-.005-.047-.016a10"
                            "4.86 104.86 0 0 1-1.18-.83c-.374-.265-.746-.531-1.118-.797-.011 0-.016"
                            "-.006-.016-.016-.01 0-.016-.005-.016-.016-.01 0-.016-.005-.016-.016h-5"
                            ".553v1.324a.39.39 0 0 1-.112.288.425.425 0 0 1-.287.111.37.37 0 0 1-.2"
                            "72-.111.389.389 0 0 1-.111-.288v-4.946c0-.054.005-.107.016-.16a.502.50"
                            "2 0 0 1 .095-.128.374.374 0 0 1 .128-.08.316.316 0 0 1 .144-.031h6.893"
                            "c.256 0 .49.048.702.143.224.085.42.218.59.4.182.18.32.377.416.59.085.2"
                            "23.127.457.127.702v.335c0 .223-.032.43-.095.622a2.107 2.107 0 0 1-.32."
                            "527c-.138.18-.292.319-.462.415-.17.106-.362.186-.575.24l.702.51c.234.1"
                            "7.469.345.703.526Zm-8.281-4.228v2.425h6.494a.954.954 0 0 0 .4-.08.776."
                            "776 0 0 0 .334-.223c.107-.106.186-.218.24-.335.053-.128.08-.266.08-.41"
                            "5v-.32a.954.954 0 0 0-.08-.398 1.232 1.232 0 0 0-.224-.351 1.228 1.228"
                            " 0 0 0-.35-.224.954.954 0 0 0-.4-.08h-6.494Zm24.67-.782c.106 0 .202.03"
                            "7.287.111a.37.37 0 0 1 .112.272.39.39 0 0 1-.112.287.425.425 0 0 1-.28"
                            "7.112h-3.64v4.579a.37.37 0 0 1-.111.272.348.348 0 0 1-.271.127.397.397"
                            " 0 0 1-.288-.127.37.37 0 0 1-.111-.272v-4.579h-3.639a.37.37 0 0 1-.271"
                            "-.111.39.39 0 0 1-.112-.287.37.37 0 0 1 .112-.272.37.37 0 0 1 .271-.11"
                            "1h8.058Zm15.782-.048c.723 0 1.34.266 1.85.798.511.532.767 1.17.767 1.9"
                            "15v2.68a.37.37 0 0 1-.112.272.397.397 0 0 1-.287.127.348.348 0 0 1-.27"
                            "2-.127.348.348 0 0 1-.127-.272v-1.196h-7.532v1.196a.348.348 0 0 1-.128"
                            ".272.348.348 0 0 1-.271.127.348.348 0 0 1-.271-.127.348.348 0 0 1-.128"
                            "-.272v-2.68c0-.745.255-1.383.766-1.915.51-.532 1.128-.798 1.851-.798h3"
                            ".894Zm-5.697 3.415h7.548v-.702c0-.532-.176-.984-.527-1.357-.362-.383-."
                            "792-.574-1.292-.574H408.5c-.51 0-.942.191-1.293.574a1.875 1.875 0 0 0-"
                            ".542 1.357v.702ZM297.898 204.5h4.16l1.792-5.152h9.408l1.824 5.152h4.44"
                            "8l-8.704-23.2h-4.288l-8.64 23.2Zm10.624-18.496 3.52 9.952h-7.008l3.488"
                            "-9.952Zm22.81 18.496h3.807v-17.216h-3.808v9.184c0 3.104-1.024 5.344-3."
                            "872 5.344s-3.168-2.272-3.168-4.608v-9.92h-3.808v10.848c0 4.096 1.664 6"
                            ".784 5.76 6.784 2.336 0 4.096-.992 5.088-2.784v2.368Zm7.678-17.216h-2."
                            "56v2.752h2.56v9.952c0 3.52.736 4.512 4.416 4.512h2.816v-2.912h-1.376c-"
                            "1.632 0-2.048-.416-2.048-2.176v-9.376h3.456v-2.752h-3.456v-4.544h-3.80"
                            "8v4.544Zm13.179-5.984h-3.809v23.2h3.808v-9.152c0-3.104 1.088-5.344 4-5"
                            ".344s3.264 2.272 3.264 4.608v9.888h3.808v-10.816c0-4.096-1.696-6.784-5"
                            ".856-6.784-2.4 0-4.224.992-5.216 2.784V181.3Zm16.86 14.624c0-3.968 2.1"
                            "44-5.92 4.544-5.92 2.4 0 4.544 1.952 4.544 5.92s-2.144 5.888-4.544 5.8"
                            "88c-2.4 0-4.544-1.92-4.544-5.888Zm4.544-9.024c-4.192 0-8.48 2.816-8.48"
                            " 9.024 0 6.208 4.288 8.992 8.48 8.992s8.48-2.784 8.48-8.992c0-6.208-4."
                            "288-9.024-8.48-9.024Zm20.057.416a10.32 10.32 0 0 0-.992-.064c-2.08.032"
                            "-3.744 1.184-4.672 3.104v-3.072h-3.744V204.5h3.808v-9.024c0-3.456 1.37"
                            "6-4.416 3.776-4.416.576 0 1.184.032 1.824.096v-3.84Zm14.665 4.672c-.70"
                            "4-3.456-3.776-5.088-7.136-5.088-3.744 0-7.008 1.952-7.008 4.992 0 3.13"
                            "6 2.272 4.448 5.184 5.024l2.592.512c1.696.32 2.976.96 2.976 2.368s-1.4"
                            "72 2.24-3.456 2.24c-2.24 0-3.52-1.024-3.872-2.784h-3.712c.416 3.264 3."
                            "232 5.664 7.456 5.664 3.904 0 7.296-1.984 7.296-5.568 0-3.36-2.656-4.4"
                            "48-6.144-5.12l-2.432-.48c-1.472-.288-2.304-.896-2.304-2.048 0-1.152 1."
                            "536-1.888 3.2-1.888 1.92 0 3.36.608 3.776 2.176h3.584Zm6.284-10.688h-3"
                            ".808v23.2h3.808v-9.152c0-3.104 1.088-5.344 4-5.344s3.264 2.272 3.264 4"
                            ".608v9.888h3.808v-10.816c0-4.096-1.696-6.784-5.856-6.784-2.4 0-4.224.9"
                            "92-5.216 2.784V181.3Zm14.076 0v3.84h3.808v-3.84h-3.808Zm0 5.984V204.5h"
                            "3.808v-17.216h-3.808Zm10.781 8.608c0-3.968 1.952-5.888 4.448-5.888 2.6"
                            "56 0 4.256 2.272 4.256 5.888 0 3.648-1.6 5.92-4.256 5.92-2.496 0-4.448"
                            "-1.952-4.448-5.92Zm-3.648-8.608V210.1h3.808v-7.872c1.024 1.696 2.816 2"
                            ".688 5.12 2.688 4.192 0 7.392-3.488 7.392-9.024 0-5.504-3.2-8.992-7.39"
                            '2-8.992-2.304 0-4.096.992-5.12 2.688v-2.304h-3.808Z" fill="#F0F6FC"/><'
                            'path class="k" stroke-dashoffset="5" stroke-dasharray="10" d="M215 545'
                            'h320"/><g transform="translate(303.88888 295) scale(0.55555)"><svg wid'
                            'th="256" height="288" viewBox="0 0 256 288" fill="#0D1017" stroke-widt'
                            'h="12" stroke="#F0F6FC" xmlns="http://www.w3.org/2000/svg"><rect x="6"'
                            ' y="6" width="52" height="196" rx="26"/><circle cx="32" cy="256" r="26'
                            '"/><rect x="102" y="6" width="52" height="84" rx="26"/><circle cx="128'
                            '" cy="144" r="26"/><rect x="102" y="198" width="52" height="84" rx="26'
                            '"/><circle cx="224" cy="32" r="26"/><rect x="198" y="86" width="52" he'
                            'ight="196" rx="26"/></svg></g><text font-family="A" x="50%" y="605" fi'
                            'll="#F0F6FC" font-size="40" dominant-baseline="central" text-anchor="m'
                            'iddle">#',
                            _zfill(_tokenId),
                            '</text><rect class="i k o" x="215" y="65" mask="url(#a)" rx="20"/><cir'
                            'cle class="j k o" cy="65" mask="url(#a)"/><circle class="j k o" cy="68'
                            '5" mask="url(#a)"/></svg>'
                        )
                    ),
                    '","attributes":[{"trait_type":"Used","value":',
                    ICurta(curta).hasUsedAuthorshipToken(_tokenId) ? "true" : "false",
                    "}]}"
                )
            )
        );
    }

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @notice Converts `_value` to a string with leading zeros to reach a
    /// minimum of 7 characters.
    /// @param _value Number to convert.
    /// @return string memory The string representation of `_value` with leading
    /// zeros.
    function _zfill(uint256 _value) internal pure returns (string memory) {
        string memory result = _value.toString();

        if (_value < 10) return string.concat("000000", result);
        else if (_value < 100) return string.concat("00000", result);
        else if (_value < 1000) return string.concat("0000", result);
        else if (_value < 10_000) return string.concat("000", result);
        else if (_value < 100_000) return string.concat("00", result);
        else if (_value < 1_000_000) return string.concat("0", result);

        return result;
    }
}
