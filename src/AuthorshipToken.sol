// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";

import { IMinimalERC721 } from "@/interfaces/IMinimalERC721.sol";

contract AuthorshipToken is IMinimalERC721, ERC721 {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted if `_address` has already claimed from the mint list.
    /// @param _address The address of the sender.
    error AlreadyClaimed(address _address);

    /// @notice Emitted if a merkle proof is invalid.
    error InvalidProof();

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The Curta / Flags contract.
    address public immutable curta;

    /// @notice Merkle root of mint mintlist.
    bytes32 public immutable merkleRoot;

    /// @notice The total supply of tokens.
    uint256 totalSupply = 0;

    /// @notice Mapping to keep track of which addresses have claimed from
    // the mint list.
    mapping(address => bool) public hasClaimed;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(address _curta, bytes32 _merkleRoot) ERC721("Authorship Token", "AUTH") {
        curta = _curta;
        merkleRoot = _merkleRoot;
    }

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

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

    function curtaMint(address _to) external {
        require(msg.sender == curta, "Only Curta can mint");

        unchecked {
            uint256 tokenId = ++totalSupply;
            _mint(_to, tokenId);
        }
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        override (ERC721, IMinimalERC721)
        returns (address)
    {
        return ownerOf(_tokenId);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return "";
    }
}
