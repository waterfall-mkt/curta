// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";

contract AuthorshipToken is ERC721 {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted if `_address` has already claimed from the mint list.
    /// @param _address The address of the sender.
    error AlreadyClaimed(address _address);

    /// @notice Emitted if a merkle proof is invalid.
    error InvalidProof();

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The Curta / Flags contract.
    address public immutable curta;

    /// @notice Merkle root of addresses on the mintlist.
    bytes32 public immutable merkleRoot;

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
    constructor(address _curta, bytes32 _merkleRoot) ERC721("Authorship Token", "AUTH") {
        curta = _curta;
        merkleRoot = _merkleRoot;
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
        if (msg.sender != curta) revert Unauthorized();

        unchecked {
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return "";
    }
}
