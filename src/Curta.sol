// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { AuthorshipToken } from "./AuthorshipToken.sol";
import { FlagsERC721 } from "./FlagsERC721.sol";
import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { IPuzzle } from "@/contracts/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/contracts/interfaces/ITokenRenderer.sol";
import { Base64 } from "@/contracts/utils/Base64.sol";

// .===========================================================================.
// | The Curta is a hand-held mechanical calculator designed by Curt           |
// | Herzstark. It is known for its extremely compact design: a small cylinder |
// | that fits in the palm of the hand.                                        |
// |---------------------------------------------------------------------------|
// | The nines' complement math breakthrough eliminated the significant        |
// | mechanical complexity created when "borrowing" during subtraction. This   |
// | drum was the key to miniaturizing the Curta.                              |
// '==========================================================================='

/// @title Curta
/// @author fiveoutofnine
/// @notice An extensible CTF, where each part is a generative puzzle, and each
/// solution is minted as an NFT ("Flag").
contract Curta is ICurta, FlagsERC721 {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The length of "Phase 1" in seconds.
    uint256 constant PHASE_ONE_LENGTH = 2 days;

    /// @notice The length of "Phase 1" and "Phase 2" combined (i.e. the solving
    /// period) in seconds.
    uint256 constant SUBMISSION_LENGTH = 5 days;

    /// @notice The fee required to submit a solution during "Phase 2".
    uint256 constant PHASE_TWO_FEE = 0.01 ether;

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurta
    AuthorshipToken public immutable override authorshipToken;

    /// @inheritdoc ICurta
    ITokenRenderer public immutable override baseRenderer;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurta
    uint32 public override puzzleId = 0;

    /// @inheritdoc ICurta
    Fermat public override fermat;

    /// @inheritdoc ICurta
    mapping(uint32 => PuzzleSolves) public override getPuzzleSolves;

    /// @inheritdoc ICurta
    mapping(uint32 => PuzzleData) public override getPuzzle;

    /// @inheritdoc ICurta
    mapping(uint32 => address) public override getPuzzleAuthor;

    /// @inheritdoc ICurta
    mapping(uint32 => ITokenRenderer) public override getPuzzleTokenRenderer;

    /// @inheritdoc ICurta
    mapping(address => mapping(uint32 => bool)) public override hasSolvedPuzzle;

    /// @inheritdoc ICurta
    mapping(uint256 => bool) public override hasUsedAuthorshipToken;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    /// @param _authorshipToken The address of the Authorship Token contract.
    /// @param _baseRenderer The address of the fallback token renderer
    /// contract.
    constructor(AuthorshipToken _authorshipToken, ITokenRenderer _baseRenderer)
        FlagsERC721("Curta", "CTF")
    {
        authorshipToken = _authorshipToken;
        baseRenderer = _baseRenderer;
    }

    /// @inheritdoc ICurta
    function solve(uint32 _puzzleId, uint256 _solution) external payable {
        // Revert if `msg.sender` has already solved the puzzle.
        if (hasSolvedPuzzle[msg.sender][_puzzleId]) {
            revert PuzzleAlreadySolved(_puzzleId);
        }

        PuzzleData memory puzzleData = getPuzzle[_puzzleId];
        IPuzzle puzzle = puzzleData.puzzle;

        // Revert if the puzzle does not exist.
        if (address(puzzle) == address(0)) revert PuzzleDoesNotExist(_puzzleId);

        // Revert if submissions are closed.
        uint40 firstSolveTimestamp = puzzleData.firstSolveTimestamp;
        uint40 solveTimestamp = uint40(block.timestamp);
        uint8 phase = _computePhase(firstSolveTimestamp, solveTimestamp);
        if (phase == 3) revert SubmissionClosed(_puzzleId);

        // Revert if the solution is incorrect.
        if (!puzzle.verify(puzzle.generate(msg.sender), _solution)) {
            revert IncorrectSolution();
        }

        // Update the puzzle's first solve timestamp if it was previously unset.
        if (firstSolveTimestamp == 0) {
            getPuzzle[_puzzleId].firstSolveTimestamp = solveTimestamp;

            // Give first solver an Authorship Token
            authorshipToken.curtaMint(msg.sender);
        }

        // Mark the puzzle as solved.
        hasSolvedPuzzle[msg.sender][_puzzleId] = true;

        // Emit event
        // TODO: change back when done
        emit PuzzleSolved({id: _puzzleId, solver: msg.sender, solution: _solution, phase: phase});

        // Mint NFT.
        unchecked {
            _mint({
                _to: msg.sender,
                _id: (uint256(_puzzleId) << 128) | getPuzzleSolves[_puzzleId].solves++,
                _puzzleId: _puzzleId,
                _phase: phase
            });

            if (phase == 1) {
                ++getPuzzleSolves[_puzzleId].phase1Solves;
            } else if (phase == 2) {
                // Revert if the puzzle is in "Phase 2," and insufficient funds
                // were sent.
                if (msg.value < PHASE_TWO_FEE) revert InsufficientFunds();
                ++getPuzzleSolves[_puzzleId].phase2Solves;
            }
        }

        // Transfer fee to the puzzle author. Refunds are not checked, in case
        // someone wants to "tip" the author.
        SafeTransferLib.safeTransferETH(getPuzzleAuthor[_puzzleId], msg.value);
    }

    /// @inheritdoc ICurta
    function addPuzzle(IPuzzle _puzzle, uint256 _tokenId) external {
        // Revert if authorship token doesn't belong to sender.
        if (msg.sender != authorshipToken.ownerOf(_tokenId)) revert Unauthorized();

        // Revert if the puzzle has already been used.
        if (hasUsedAuthorshipToken[_tokenId]) revert AuthorshipTokenAlreadyUsed(_tokenId);

        // Mark token as used.
        hasUsedAuthorshipToken[_tokenId] = true;

        unchecked {
            uint32 curPuzzleId = ++puzzleId;

            // Add puzzle.
            getPuzzle[curPuzzleId] = PuzzleData({
                puzzle: _puzzle,
                addedTimestamp: uint40(block.timestamp),
                firstSolveTimestamp: 0
            });

            // Add puzzle author.
            getPuzzleAuthor[curPuzzleId] = msg.sender;

            // Emit events.
            emit PuzzleAdded(curPuzzleId, msg.sender, _puzzle);
        }
    }

    /// @inheritdoc ICurta
    function setPuzzleTokenRenderer(uint32 _puzzleId, ITokenRenderer _tokenRenderer) external {
        // Revert if `msg.sender` is not the author of the puzzle.
        if (getPuzzleAuthor[_puzzleId] != msg.sender) revert Unauthorized();

        // Set token renderer.
        getPuzzleTokenRenderer[_puzzleId] = _tokenRenderer;

        // Emit events.
        emit PuzzleTokenRendererUpdated(_puzzleId, _tokenRenderer);
    }

    /// @inheritdoc ICurta
    function setFermat(uint32 _puzzleId) external {
        // Revert if the puzzle has never been solved.
        PuzzleData memory puzzleData = getPuzzle[_puzzleId];
        if (puzzleData.firstSolveTimestamp == 0) revert PuzzleNotSolved(_puzzleId);

        // Revert if the puzzle is already Fermat.
        if (fermat.puzzleId == _puzzleId) revert PuzzleAlreadyFermat(_puzzleId);

        unchecked {
            uint40 timeTaken = puzzleData.firstSolveTimestamp - puzzleData.addedTimestamp;

            // Revert if the puzzle is not Fermat.
            if (timeTaken < fermat.timeTaken) revert PuzzleNotFermat(_puzzleId);

            // Set Fermat.
            fermat.puzzleId = _puzzleId;
            fermat.timeTaken = timeTaken;
        }

        // Transfer Fermat to puzzle author.
        address puzzleAuthor = getPuzzleAuthor[_puzzleId];
        address currentOwner = getTokenData[0].owner;

        unchecked {
            // Delete ownership information about Fermat, if the owner is not
            // `address(0)`.
            if (currentOwner != address(0)) {
                getUserBalances[currentOwner].balance--;

                delete getApproved[0];

                // Emit burn event.
                emit Transfer(currentOwner, address(0), 0);
            }

            // Increment new Fermat author's balance.
            getUserBalances[puzzleAuthor].balance++;
        }

        // Set new Fermat owner.
        getTokenData[0].owner = puzzleAuthor;

        // Emit mint event.
        emit Transfer(address(0), puzzleAuthor, 0);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc FlagsERC721
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        require(getTokenData[_tokenId].owner != address(0), "NOT_MINTED");

        return "";
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// @notice Computes the phase the puzzle was at at some timestamp.
    /// @param _firstSolveTimestamp The timestamp of the first solve.
    /// @param _solveTimestamp The timestamp of the solve.
    /// @return phase The phase of the puzzle: "Phase 0" refers to the period
    /// before the puzzle has been solved, "Phase 1" refers to the period 2 days
    /// after the first solve, "Phase 2" refers to the period 3 days after the
    /// end of "Phase 1", and "Phase 3" is when submissions are closed.
    function _computePhase(uint40 _firstSolveTimestamp, uint40 _solveTimestamp)
        internal
        pure
        returns (uint8 phase)
    {
        // Equivalent to:
        // if (_firstSolveTimestamp == 0) {
        //     phase = 0;
        // } else {
        //     if (_solveTimestamp > _firstSolveTimestamp + SUBMISSION_LENGTH) {
        //         phase = 3;
        //     } else if (_solveTimestamp > _firstSolveTimestamp + PHASE_ONE_LENGTH) {
        //         phase = 2;
        //     } else {
        //         phase = 1;
        //     }
        // }
        assembly {
            phase :=
                mul(
                    iszero(iszero(_firstSolveTimestamp)),
                    add(
                        1,
                        add(
                            gt(_solveTimestamp, add(_firstSolveTimestamp, PHASE_ONE_LENGTH)),
                            gt(_solveTimestamp, add(_firstSolveTimestamp, SUBMISSION_LENGTH))
                        )
                    )
                )
        }
    }
}
