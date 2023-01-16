// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

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
    /// @param puzzleId The ID of the puzzle that the token represents.
    /// @param solveTimestamp The timestamp of when the token was solved/minted.
    struct TokenData {
        address owner;
        uint32 puzzleId;
        uint40 solveTimestamp;
    }

    /// @param phase0Solves The number of puzzles someone solved during
    /// "Phase 0."
    /// @param phase1Solves The number of puzzles someone solved during
    /// "Phase 1."
    /// @param phase2Solves The number of puzzles someone solved during
    /// "Phase 2."
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

    string public name;

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

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function _mint(address _to, uint256 _id, uint32 _puzzleId, uint8 _phase) internal {
        // We do not check whether the `_to` is `address(0)` or that the token
        // was previously minted because {Curta} ensures these conditions are
        // never true.

        unchecked {
            ++getUserBalances[_to].balance;
            ++getUserBalances[_to].solves;

            if (_phase == 0) ++getUserBalances[_to].phase0Solves;
            else if (_phase == 1) ++getUserBalances[_to].phase1Solves;
            else ++getUserBalances[_to].phase2Solves;
        }

        getTokenData[_id] =
            TokenData({owner: _to, puzzleId: _puzzleId, solveTimestamp: uint40(block.timestamp)});

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

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[_id] = _spender;

        emit Approval(owner, _spender, _id);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(address _from, address _to, uint256 _id) public virtual {
        require(_from == getTokenData[_id].owner, "WRONG_FROM");

        require(_to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == _from || isApprovedForAll[_from][msg.sender]
                || msg.sender == getApproved[_id],
            "NOT_AUTHORIZED"
        );

        unchecked {
            getUserBalances[_from].balance--;

            getUserBalances[_to].balance++;
        }

        getTokenData[_id].owner = _to;

        delete getApproved[_id];

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

    function tokenURI(uint256 _id) external view virtual returns (string memory);

    // -------------------------------------------------------------------------
    // ERC165
    // -------------------------------------------------------------------------

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01FFC9A7 // ERC165 Interface ID for ERC165
            || _interfaceId == 0x80AC58CD // ERC165 Interface ID for ERC721
            || _interfaceId == 0x5B5E139F; // ERC165 Interface ID for ERC721Metadata
    }
}
