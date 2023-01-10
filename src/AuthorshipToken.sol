// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Owned } from "solmate/auth/Owned.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { LibString } from "solmate/utils/LibString.sol";
import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";

import { ICurta } from "@/interfaces/ICurta.sol";
import { Base64 } from "@/utils/Base64.sol";

/// @title AuthorshipToken
contract AuthorshipToken is ERC721, Owned {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The number of seconds an additional token is made available for
    /// minting by the author.
    uint256 constant ISSUE_LENGTH = 1 days;

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
    function mint(bytes32[] calldata _proof) external {
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

    /// @inheritdoc ERC721
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "NOT_MINTED");

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"Authorship Token #',
                    LibString.toString(_tokenId),
                    '","description":"Token that grants user permission to add a puzzle to Curta",',
                    '"image_data":"data:image/svg+xml;base64,',
                    // TODO: Update this to use the actual SVG
                    Base64.encode(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="100%" height="100%"/><text x="8" y="40" style="fill:#fff;font-family:serif;font-size:32px">Authorship Token</text></svg>'
                        )
                    ),
                    '","attributes":[{"trait_type":"Used","value":',
                    ICurta(curta).hasUsedAuthorshipToken(_tokenId) ? "true" : "false",
                    "]}"
                )
            )
        );
    }
}
