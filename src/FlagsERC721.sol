// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

/// @title The Flags ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice A ``Flag'' is an NFT minted to a player when they successfuly solve
/// a puzzle.
/// @dev The NFT with token ID 0 is reserved to denote ``Fermat''—the author's
/// whose puzzle went the longest unsolved.
abstract contract FlagsERC721 {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @param owner The owner of the token.
    /// @param solveTimestamp The timestamp of when the token was solved/minted.
    /// @param solveMetadata A bitpacked `uint56` containing the following
    /// information:
    ///     * The first 28 bits are the first 28 bits of the solver.
    ///     * The last 28 bits are the last 28 bits of the solution.
    struct TokenData {
        address owner;
        uint40 solveTimestamp;
        uint56 solveMetadata;
    }

    /// @param phase0Solves The number of puzzles someone solved during Phase 0.
    /// @param phase1Solves The number of puzzles someone solved during Phase 1.
    /// @param phase2Solves The number of puzzles someone solved during Phase 2.
    /// @param solves The total number of solves someone has.
    /// @param balance The number of tokens someone owns.
    struct UserBalance {
        uint32 phase0Solves;
        uint32 phase1Solves;
        uint32 phase2Solves;
        uint32 solves;
        uint32 balance;
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata Storage
    // -------------------------------------------------------------------------

    /// @notice The name of the contract.
    string public name;

    /// @notice An abbreviated name for the contract.
    string public symbol;

    // -------------------------------------------------------------------------
    // ERC721 Storage (+ Custom)
    // -------------------------------------------------------------------------

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => TokenData) public getTokenData;

    mapping(address => UserBalance) public getUserBalances;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    /// @param _name The name of the contract.
    /// @param _symbol An abbreviated name for the contract.
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// @notice Mints a Flag token to `_to`.
    /// @dev This function is only called by {Curta}, so it makes a few
    /// assumptions. For example, the ID of the token is always in the form
    /// `(puzzleId << 128) + zeroIndexedSolveRanking`.
    /// @param _to The address to mint the token to.
    /// @param _id The ID of the token.
    /// @param _solveMetadata The metadata for the solve (see
    /// {FlagsERC721.TokenData}).
    /// @param _phase The phase the token was solved in.
    function _mint(address _to, uint256 _id, uint56 _solveMetadata, uint8 _phase) internal {
        // We do not check whether the `_to` is `address(0)` or that the token
        // was previously minted because {Curta} ensures these conditions are
        // never true.

        unchecked {
            ++getUserBalances[_to].balance;

            // `_mint` is only called when a puzzle is solved, so we can safely
            // increment the solve count.
            ++getUserBalances[_to].solves;

            // Same logic as the previous comment here.
            if (_phase == 0) ++getUserBalances[_to].phase0Solves;
            else if (_phase == 1) ++getUserBalances[_to].phase1Solves;
            else ++getUserBalances[_to].phase2Solves;
        }

        getTokenData[_id] = TokenData({
            owner: _to,
            solveMetadata: _solveMetadata,
            solveTimestamp: uint40(block.timestamp)
        });

        // Emit event.
        emit Transfer(address(0), _to, _id);
    }

    // -------------------------------------------------------------------------
    // ERC721
    // -------------------------------------------------------------------------

    function ownerOf(uint256 _id) public view returns (address owner) {
        require((owner = getTokenData[_id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ZERO_ADDRESS");

        return getUserBalances[_owner].balance;
    }

    function approve(address _spender, uint256 _id) external {
        address owner = getTokenData[_id].owner;

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        // Set the spender as approved for the token.
        getApproved[_id] = _spender;

        // Emit event.
        emit Approval(owner, _spender, _id);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        // Set the operator as approved for the sender.
        isApprovedForAll[msg.sender][_operator] = _approved;

        // Emit event.
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(address _from, address _to, uint256 _id) public virtual {
        // Revert if the token is not being transferred from the current owner.
        require(_from == getTokenData[_id].owner, "WRONG_FROM");

        // Revert if the recipient is the zero address.
        require(_to != address(0), "INVALID_RECIPIENT");

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(
            msg.sender == _from || isApprovedForAll[_from][msg.sender]
                || msg.sender == getApproved[_id],
            "NOT_AUTHORIZED"
        );

        // Update balances.
        unchecked {
            // Will never underflow because of the token ownership check above.
            getUserBalances[_from].balance--;

            getUserBalances[_to].balance++;
        }

        // Set new owner.
        getTokenData[_id].owner = _to;

        // Clear previous approval data for the token.
        delete getApproved[_id];

        // Emit event.
        emit Transfer(_from, _to, _id);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, bytes calldata _data)
        external
    {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, _data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _tokenId The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory);

    // -------------------------------------------------------------------------
    // ERC165
    // -------------------------------------------------------------------------

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01FFC9A7 // ERC165 Interface ID for ERC165
            || _interfaceId == 0x80AC58CD // ERC165 Interface ID for ERC721
            || _interfaceId == 0x5B5E139F; // ERC165 Interface ID for ERC721Metadata
    }
}
