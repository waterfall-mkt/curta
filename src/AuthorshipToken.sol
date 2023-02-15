// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IShieldsAPI } from "shields-api/interfaces/IShieldsAPI.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { LibString } from "solmate/utils/LibString.sol";
import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";

import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { Base64 } from "@/contracts/utils/Base64.sol";

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
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The number of seconds an additional token is made available for
    /// minting by the author.
    uint256 constant ISSUE_LENGTH = 1 days;

    /// @notice The shields API contract.
    /// @dev This is the mainnet address.
    IShieldsAPI constant shieldsAPI = IShieldsAPI(0x740CBbF0116a82F64e83E1AE68c92544870B0C0F);

    /// @notice Salt used to compute the seed in {AuthorshipToken-tokenURI}.
    bytes32 constant SALT = bytes32("Curta.AuthorshipToken");

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted if `_address` has already claimed from the mint list.
    /// @param _address The address of the sender.
    error AlreadyClaimed(address _address);

    /// @notice Emitted if a merkle proof is invalid.
    error InvalidProof();

    /// @notice Emitted when there are no tokens available to claim.
    error NoTokensAvailable();

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @notice The Curta / Flags contract.
    address public immutable curta;

    /// @notice Merkle root of addresses on the mintlist.
    bytes32 public immutable merkleRoot;

    /// @notice The timestamp of when the contract was deployed.
    uint256 public immutable deployTimestamp;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The number of tokens that have been claimed by the owner.
    uint256 public numClaimedByOwner;

    /// @notice The total supply of tokens.
    uint256 public totalSupply;

    /// @notice Mapping to keep track of which addresses have claimed from
    // the mint list.
    mapping(address => bool) public hasClaimed;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _curta The Curta / Flags contract.
    /// @param _merkleRoot Merkle root of addresses on the mintlist.
    constructor(address _curta, bytes32 _merkleRoot)
        ERC721("Authorship Token", "AUTH")
        Owned(msg.sender)
    {
        curta = _curta;
        merkleRoot = _merkleRoot;
        deployTimestamp = block.timestamp;
    }

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a token to `msg.sender` if the merkle proof is valid, and
    /// `msg.sender` has not claimed a token yet.
    /// @param _proof The merkle proof.
    function claim(bytes32[] calldata _proof) external {
        // Revert if the user has already claimed.
        if (hasClaimed[msg.sender]) revert AlreadyClaimed(msg.sender);

        // Revert if proof is invalid (i.e. not in the Merkle tree).
        if (!MerkleProofLib.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert InvalidProof();
        }

        // Mark user has having claimed from the mint list.
        hasClaimed[msg.sender] = true;

        unchecked {
            uint256 tokenId = ++totalSupply;

            _mint(msg.sender, tokenId);
        }
    }

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
    /// every `ISSUE_LENGTH` seconds.
    /// @param _to The address to mint the token to.
    function ownerMint(address _to) external onlyOwner {
        unchecked {
            uint256 numIssued = (block.timestamp - deployTimestamp) / ISSUE_LENGTH;
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

        // Generate seed.
        uint256 seed = uint256(keccak256(abi.encodePacked(_tokenId, SALT)));

        // Bitpacked colors.
        uint256 colors = 0x6351CEFF00FFB300FF6B00B5000A007FFF78503C323232FE7FFF6C28A2FF007A;

        // Shuffle `colors` by performing 4 iterations of Fisher-Yates shuffle.
        // We do this to pick 4 unique colors from `colors`.
        unchecked {
            uint256 shift = 24 * (seed % 11);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ 0xFFFFFF))
                | ((colors & 0xFFFFFF) << shift)
                | ((colors >> shift) & 0xFFFFFF);
            seed >>= 4;

            shift = 24 * (seed % 10);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 24)))
                | (((colors >> 24) & 0xFFFFFF) << shift)
                | (((colors >> shift) & 0xFFFFFF) << 24);
            seed >>= 4;

            shift = 24 * (seed % 9);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 48)))
                | (((colors >> 48) & 0xFFFFFF) << shift)
                | (((colors >> shift) & 0xFFFFFF) << 48);
            seed >>= 4;

            shift = 24 * (seed & 7);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 72)))
                | (((colors >> 72) & 0xFFFFFF) << shift)
                | (((colors >> shift) & 0xFFFFFF) << 72);
            seed >>= 3;
        }

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"Authorship Token #',
                    _tokenId.toString(),
                    '","description":"This token allows 1 puzzle to be added to Curta. Once it has '
                    'been used, it can never be used again.","image_data":"data:image/svg+xml;base6'
                    '4,',
                    Base64.encode(
                        abi.encodePacked(
                            '<svg width="320" height="620" viewBox="0 0 320 620" fill="none" xmlns='
                            '"http://www.w3.org/2000/svg"><style>rect.a{filter:url(#c)drop-shadow(0'
                            ' 0 32px #007fff);rx:32px;fill:#fff;width:64px}rect.b{filter:drop-shado'
                            'w(0 0 8px #007fff);rx:24px;fill:#000;width:48px}rect.c{height:208px}re'
                            'ct.d{height:96px}rect.e{height:64px}rect.f{height:192px}rect.g{height:'
                            '80px}rect.h{height:48px}rect.i{width:320px;height:620px;rx:20px}circle'
                            '.j{cx:160px;r:20px}</style><defs><radialGradient id="b"><stop style="s'
                            'top-color:#007fff;stop-opacity:1"/><stop offset="100%" style="stop-opa'
                            'city:0"/></radialGradient><filter id="c"><feGaussianBlur stdDeviation='
                            '"8" in="SourceGraphic" result="offset-blur"/><feComposite operator="ou'
                            't" in="SourceGraphic" in2="offset-blur" result="inverse"/><feFlood flo'
                            'od-color="#007FFF" flood-opacity=".95" result="color"/><feComposite op'
                            'erator="in" in="color" in2="inverse" result="shadow"/><feComposite in='
                            '"shadow" in2="SourceGraphic"/><feComposite operator="atop" in="shadow"'
                            ' in2="SourceGraphic"/></filter><mask id="a"><rect class="i" fill="#fff'
                            '"/><circle class="j" fill="#000"/><circle class="j" cy="620" fill="#00'
                            '0"/></mask></defs><rect class="i" fill="#0D1017" mask="url(#a)"/><circ'
                            'le fill="url(#b)" cx="160" cy="320" r="200"/><circle fill="#0D1017" cl'
                            'ass="j" cy="60" stroke="#27303D"/><g transform="translate(144 45) scal'
                            'e(.0625)"><rect width="512" height="512" fill="#0D1017" rx="256"/><rec'
                            't class="a c" x="128" y="112"/><rect class="b f" x="136" y="120"/><rec'
                            't class="a e" x="128" y="336"/><rect class="b h" x="136" y="344"/><rec'
                            't class="a d" x="224" y="112"/><rect class="b g" x="232" y="120"/><rec'
                            't class="a e" x="224" y="224"/><rect class="b h" x="232" y="232"/><rec'
                            't class="a d" x="224" y="304"/><rect class="b g" x="232" y="312"/><rec'
                            't class="a c" x="320" y="192"/><rect class="b f" x="328" y="200"/><rec'
                            't class="a e" x="320" y="112"/><rect class="b h" x="328" y="120"/></g>'
                            '<path d="M123.814 103.856c-.373 0-.718-.063-1.037-.191a2.829 2.829 0 0'
                            ' 1-.878-.606 2.828 2.828 0 0 1-.606-.878 2.767 2.767 0 0 1-.193-1.037v'
                            '-.336c0-.372.064-.723.192-1.053.138-.319.34-.611.606-.877a2.59 2.59 0 '
                            '0 1 .878-.59 2.58 2.58 0 0 1 1.038-.208h4.26c.245 0 .48.032.703.096.21'
                            '2.053.425.143.638.27.223.118.415.256.574.416.16.16.304.345.431.558.043'
                            '.064.07.133.08.208a.301.301 0 0 1-.016.095.346.346 0 0 1-.175.256.42.4'
                            '2 0 0 1-.32.032.333.333 0 0 1-.239-.192 3.016 3.016 0 0 0-.303-.399 2.'
                            '614 2.614 0 0 0-.415-.303 1.935 1.935 0 0 0-.463-.191 1.536 1.536 0 0 '
                            '0-.495-.048c-.712 0-1.42-.006-2.122-.016-.713 0-1.425.005-2.138.016-.2'
                            '66 0-.51.042-.734.127-.234.096-.442.24-.623.431a1.988 1.988 0 0 0-.43.'
                            '623 1.961 1.961 0 0 0-.144.75v.335a1.844 1.844 0 0 0 .574 1.356 1.844 '
                            '1.844 0 0 0 1.356.574h4.261c.17 0 .33-.015.48-.047a2.02 2.02 0 0 0 .44'
                            '6-.192c.149-.074.282-.165.399-.271.106-.107.207-.229.303-.367a.438.438'
                            ' 0 0 1 .255-.144c.096-.01.187.01.272.064a.35.35 0 0 1 .16.24.306.306 0'
                            ' 0 1-.033.27 2.653 2.653 0 0 1-.43.527c-.16.139-.346.266-.559.383-.213'
                            '.117-.42.197-.622.24-.213.053-.436.08-.67.08h-4.262Zm17.553 0c-.713 0-'
                            '1.324-.266-1.835-.797a2.69 2.69 0 0 1-.766-1.931v-2.665c0-.117.037-.21'
                            '3.112-.287a.37.37 0 0 1 .27-.112c.118 0 .214.037.288.112a.39.39 0 0 1 '
                            '.112.287v2.664c0 .533.18.99.542 1.373a1.71 1.71 0 0 0 1.293.559h3.878c'
                            '.51 0 .941-.187 1.292-.559a1.93 1.93 0 0 0 .543-1.372v-2.665a.39.39 0 '
                            '0 1 .111-.287.389.389 0 0 1 .288-.112.37.37 0 0 1 .271.112.39.39 0 0 1'
                            ' .112.287v2.664c0 .756-.256 1.4-.766 1.932-.51.531-1.128.797-1.851.797'
                            'h-3.894Zm23.824-.718a.456.456 0 0 1 .16.192c.01.042.016.09.016.143a.47'
                            '.47 0 0 1-.016.112.355.355 0 0 1-.143.208.423.423 0 0 1-.24.063h-.048a'
                            '.141.141 0 0 1-.064-.016c-.02 0-.037-.005-.047-.016a104.86 104.86 0 0 '
                            '1-1.18-.83c-.374-.265-.746-.531-1.118-.797-.011 0-.016-.006-.016-.016-'
                            '.01 0-.016-.005-.016-.016-.01 0-.016-.005-.016-.016h-5.553v1.324a.39.3'
                            '9 0 0 1-.112.288.425.425 0 0 1-.287.111.37.37 0 0 1-.272-.111.389.389 '
                            '0 0 1-.111-.288v-4.946c0-.054.005-.107.016-.16a.502.502 0 0 1 .095-.12'
                            '8.374.374 0 0 1 .128-.08.316.316 0 0 1 .144-.031h6.893c.256 0 .49.048.'
                            '702.143.224.085.42.218.59.4.182.18.32.377.416.59.085.223.127.457.127.7'
                            '02v.335c0 .223-.032.43-.095.622a2.107 2.107 0 0 1-.32.527c-.138.18-.29'
                            '2.319-.462.415-.17.106-.362.186-.575.24l.702.51c.234.17.469.345.703.52'
                            '6Zm-8.281-4.228v2.425h6.494a.954.954 0 0 0 .4-.08.776.776 0 0 0 .334-.'
                            '223c.107-.106.186-.218.24-.335.053-.128.08-.266.08-.415v-.32a.954.954 '
                            '0 0 0-.08-.398 1.232 1.232 0 0 0-.224-.351 1.228 1.228 0 0 0-.35-.224.'
                            '954.954 0 0 0-.4-.08h-6.494Zm24.67-.782c.106 0 .202.037.287.111a.37.37'
                            ' 0 0 1 .112.272.39.39 0 0 1-.112.287.425.425 0 0 1-.287.112h-3.64v4.57'
                            '9a.37.37 0 0 1-.111.272.348.348 0 0 1-.271.127.397.397 0 0 1-.288-.127'
                            '.37.37 0 0 1-.111-.272V98.91h-3.639a.37.37 0 0 1-.271-.111.39.39 0 0 1'
                            '-.112-.287.37.37 0 0 1 .112-.272.37.37 0 0 1 .271-.111h8.058Zm15.782-.'
                            '048c.723 0 1.34.266 1.85.798.511.532.767 1.17.767 1.915v2.68a.37.37 0 '
                            '0 1-.112.272.397.397 0 0 1-.287.127.348.348 0 0 1-.272-.127.348.348 0 '
                            '0 1-.127-.272v-1.196h-7.532v1.196a.348.348 0 0 1-.128.272.348.348 0 0 '
                            '1-.271.127.348.348 0 0 1-.271-.127.348.348 0 0 1-.128-.272v-2.68c0-.74'
                            '5.255-1.383.766-1.915.51-.532 1.128-.798 1.851-.798h3.894Zm-5.697 3.41'
                            '5h7.548v-.702c0-.532-.176-.984-.527-1.357-.362-.383-.792-.574-1.292-.5'
                            '74H193.5c-.51 0-.942.191-1.293.574a1.875 1.875 0 0 0-.542 1.357v.702ZM'
                            '82.898 139.5h4.16l1.792-5.152h9.408l1.824 5.152h4.448l-8.704-23.2h-4.2'
                            '88l-8.64 23.2Zm10.624-18.496 3.52 9.952h-7.008l3.488-9.952Zm22.81 18.4'
                            '96h3.807v-17.216h-3.808v9.184c0 3.104-1.024 5.344-3.872 5.344s-3.168-2'
                            '.272-3.168-4.608v-9.92h-3.808v10.848c0 4.096 1.664 6.784 5.76 6.784 2.'
                            '336 0 4.096-.992 5.088-2.784v2.368Zm7.678-17.216h-2.56v2.752h2.56v9.95'
                            '2c0 3.52.736 4.512 4.416 4.512h2.816v-2.912h-1.376c-1.632 0-2.048-.416'
                            '-2.048-2.176v-9.376h3.456v-2.752h-3.456v-4.544h-3.808v4.544Zm13.179-5.'
                            '984h-3.809v23.2h3.808v-9.152c0-3.104 1.088-5.344 4-5.344s3.264 2.272 3'
                            '.264 4.608v9.888h3.808v-10.816c0-4.096-1.696-6.784-5.856-6.784-2.4 0-4'
                            '.224.992-5.216 2.784V116.3Zm16.86 14.624c0-3.968 2.144-5.92 4.544-5.92'
                            ' 2.4 0 4.544 1.952 4.544 5.92s-2.144 5.888-4.544 5.888c-2.4 0-4.544-1.'
                            '92-4.544-5.888Zm4.544-9.024c-4.192 0-8.48 2.816-8.48 9.024 0 6.208 4.2'
                            '88 8.992 8.48 8.992s8.48-2.784 8.48-8.992c0-6.208-4.288-9.024-8.48-9.0'
                            '24Zm20.057.416a10.32 10.32 0 0 0-.992-.064c-2.08.032-3.744 1.184-4.672'
                            ' 3.104v-3.072h-3.744V139.5h3.808v-9.024c0-3.456 1.376-4.416 3.776-4.41'
                            '6.576 0 1.184.032 1.824.096v-3.84Zm14.665 4.672c-.704-3.456-3.776-5.08'
                            '8-7.136-5.088-3.744 0-7.008 1.952-7.008 4.992 0 3.136 2.272 4.448 5.18'
                            '4 5.024l2.592.512c1.696.32 2.976.96 2.976 2.368s-1.472 2.24-3.456 2.24'
                            'c-2.24 0-3.52-1.024-3.872-2.784h-3.712c.416 3.264 3.232 5.664 7.456 5.'
                            '664 3.904 0 7.296-1.984 7.296-5.568 0-3.36-2.656-4.448-6.144-5.12l-2.4'
                            '32-.48c-1.472-.288-2.304-.896-2.304-2.048 0-1.152 1.536-1.888 3.2-1.88'
                            '8 1.92 0 3.36.608 3.776 2.176h3.584Zm6.284-10.688h-3.808v23.2h3.808v-9'
                            '.152c0-3.104 1.088-5.344 4-5.344s3.264 2.272 3.264 4.608v9.888h3.808v-'
                            '10.816c0-4.096-1.696-6.784-5.856-6.784-2.4 0-4.224.992-5.216 2.784V116'
                            '.3Zm14.076 0v3.84h3.808v-3.84h-3.808Zm0 5.984V139.5h3.808v-17.216h-3.8'
                            '08Zm10.781 8.608c0-3.968 1.952-5.888 4.448-5.888 2.656 0 4.256 2.272 4'
                            '.256 5.888 0 3.648-1.6 5.92-4.256 5.92-2.496 0-4.448-1.952-4.448-5.92Z'
                            'm-3.648-8.608V145.1h3.808v-7.872c1.024 1.696 2.816 2.688 5.12 2.688 4.'
                            '192 0 7.392-3.488 7.392-9.024 0-5.504-3.2-8.992-7.392-8.992-2.304 0-4.'
                            '096.992-5.12 2.688v-2.304h-3.808Z" fill="#F0F6FC"/><path stroke="#2730'
                            '3D" stroke-dasharray="10" d="M-5 480h325"/>',
                            shieldsAPI.getShieldSVG({
                                field: uint16(seed % 300),
                                colors: [
                                    uint24(colors & 0xFFFFFF),
                                    uint24((colors >> 24) & 0xFFFFFF),
                                    uint24((colors >> 48) & 0xFFFFFF),
                                    uint24((colors >> 72) & 0xFFFFFF)
                                ],
                                hardware: uint16((seed >> 9) % 120),
                                frame: uint16((seed >> 17) % 5)
                            }),
                            '<text x="50%" y="560" fill="#F0F6FC" font-family="monospace" style="fo'
                            'nt-size:40px" dominant-baseline="bottom" text-anchor="middle">#',
                            _zfill(_tokenId),
                            '</text><rect class="i" mask="url(#a)" stroke="#27303D" stroke-width="2'
                            '"/><circle class="j" stroke="#27303D"/><circle class="j" cy="620" stro'
                            'ke="#27303D"/></svg>'
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
        else if (_value < 10000) return string.concat("000", result);
        else if (_value < 100000) return string.concat("00", result);
        else if (_value < 1000000) return string.concat("0", result);

        return result;
    }
}
