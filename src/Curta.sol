// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// .===========================================================================.
// | The Curta is a hand-held mechanical calculator designed by Curt           |
// | Herzstark. It is known for its extremely compact design: a small cylinder |
// | that fits in the palm of the hand.                                        |
// |---------------------------------------------------------------------------|
// | The nines' complement math breakthrough eliminated the significant        |
// | mechanical complexity created when ``borrowing'' during subtraction. This |
// | drum was the key to miniaturizing the Curta.                              |
// '==========================================================================='

import { Base64 } from "solady/utils/Base64.sol";
import { LibString } from "solady/utils/LibString.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { FlagRenderer } from "./FlagRenderer.sol";
import { FlagsERC721 } from "./FlagsERC721.sol";
import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { IPuzzle } from "@/contracts/interfaces/IPuzzle.sol";

/// @title Curta
/// @author fiveoutofnine
/// @notice A CTF protocol, where players create and solve EVM puzzles to earn
/// NFTs (``Flag'').
contract Curta is ICurta, FlagsERC721, Owned {
    using LibString for uint256;

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The length of Phase 1 in seconds.
    uint256 constant PHASE_ONE_LENGTH = 2 days;

    /// @notice The length of Phase 1 and Phase 2 combined (i.e. the solving
    /// period) in seconds.
    uint256 constant SUBMISSION_LENGTH = 5 days;

    /// @notice The minimum fee required to submit a solution during Phase 2.
    /// @dev This fee is transferred to the author of the relevant puzzle. Any
    /// excess fees will also be transferred to the author. Note that the author
    /// will receive at least 0.01 ether per Phase 2 solve.
    uint256 constant PHASE_TWO_MINIMUM_FEE = 0.02 ether;

    /// @notice The protocol fee required to submit a solution during Phase 2.
    /// @dev This fee is transferred to the address returned by `owner`.
    uint256 constant PHASE_TWO_PROTOCOL_FEE = 0.01 ether;

    /// @notice The default Flag colors.
    uint120 constant DEFAULT_FLAG_COLORS = 0x181E28181E2827303DF0F6FC94A3B3;

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurta
    AuthorshipToken public immutable override authorshipToken;

    /// @inheritdoc ICurta
    FlagRenderer public immutable override flagRenderer;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurta
    uint32 public override puzzleId = 0;

    /// @inheritdoc ICurta
    Fermat public override fermat;

    /// @inheritdoc ICurta
    mapping(uint32 => PuzzleColorsAndSolves) public override getPuzzleColorsAndSolves;

    /// @inheritdoc ICurta
    mapping(uint32 => PuzzleData) public override getPuzzle;

    /// @inheritdoc ICurta
    mapping(uint32 => address) public override getPuzzleAuthor;

    /// @inheritdoc ICurta
    mapping(address => mapping(uint32 => bool)) public override hasSolvedPuzzle;

    /// @inheritdoc ICurta
    mapping(uint256 => bool) public override hasUsedAuthorshipToken;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    /// @param _authorshipToken The address of the Authorship Token contract.
    /// @param _flagRenderer The address of the Flag metadata and art renderer
    /// contract.
    constructor(AuthorshipToken _authorshipToken, FlagRenderer _flagRenderer)
        FlagsERC721("Curta", "CTF")
        Owned(msg.sender)
    {
        authorshipToken = _authorshipToken;
        flagRenderer = _flagRenderer;
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
            ++getPuzzleColorsAndSolves[_puzzleId].phase0Solves;

            // Give first solver an Authorship Token
            authorshipToken.curtaMint(msg.sender);
        }

        // Mark the puzzle as solved.
        hasSolvedPuzzle[msg.sender][_puzzleId] = true;

        uint256 ethRemaining = msg.value;
        unchecked {
            // Mint NFT.
            _mint({
                _to: msg.sender,
                _id: (uint256(_puzzleId) << 128) | getPuzzleColorsAndSolves[_puzzleId].solves++,
                _solveMetadata: uint56(((uint160(msg.sender) >> 132) << 28) | (_solution & 0xFFFFFFF)),
                _phase: phase
            });

            if (phase == 1) {
                ++getPuzzleColorsAndSolves[_puzzleId].phase1Solves;
            } else if (phase == 2) {
                // Revert if the puzzle is in Phase 2, and insufficient funds
                // were sent.
                if (ethRemaining < PHASE_TWO_MINIMUM_FEE) revert InsufficientFunds();
                ++getPuzzleColorsAndSolves[_puzzleId].phase2Solves;

                // Transfer protocol fee to `owner`.
                SafeTransferLib.safeTransferETH(owner, PHASE_TWO_PROTOCOL_FEE);

                // Subtract protocol fee from total value.
                ethRemaining -= PHASE_TWO_PROTOCOL_FEE;
            }
        }

        // Transfer untransferred funds to the puzzle author. Refunds are not
        // checked, in case someone wants to ``tip'' the author.
        SafeTransferLib.safeTransferETH(getPuzzleAuthor[_puzzleId], ethRemaining);

        // Emit event
        emit SolvePuzzle({ id: _puzzleId, solver: msg.sender, solution: _solution, phase: phase });
    }

    /// @inheritdoc ICurta
    function addPuzzle(IPuzzle _puzzle, uint256 _tokenId) external {
        // Revert if the Authorship Token doesn't belong to sender.
        if (msg.sender != authorshipToken.ownerOf(_tokenId)) revert Unauthorized();

        // Revert if the puzzle has already been used.
        if (hasUsedAuthorshipToken[_tokenId]) revert AuthorshipTokenAlreadyUsed(_tokenId);

        // Revert if puzzle address is the zero address or the Curta address
        if (address(_puzzle) == address(0) || address(_puzzle) == address(this)) {
            revert PuzzleInvalidAddress();
        }

        // Revert if puzzle name is an empty string or not implemented.
        if (bytes(_puzzle.name()).length == 0) revert PuzzleNotNamed();

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

            // Add puzzle Flag colors with default colors.
            getPuzzleColorsAndSolves[curPuzzleId].colors = DEFAULT_FLAG_COLORS;

            // Emit events.
            emit AddPuzzle(curPuzzleId, msg.sender, _puzzle);
        }
    }

    /// @inheritdoc ICurta
    function setPuzzleColors(uint32 _puzzleId, uint120 _colors) external {
        // Revert if `msg.sender` is not the author of the puzzle.
        if (getPuzzleAuthor[_puzzleId] != msg.sender) revert Unauthorized();

        // Set puzzle colors.
        getPuzzleColorsAndSolves[_puzzleId].colors = _colors;

        // Emit events.
        emit UpdatePuzzleColors(_puzzleId, _colors);
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
        TokenData memory tokenData = getTokenData[_tokenId];
        require(tokenData.owner != address(0), "NOT_MINTED");

        // Puzzle is Fermat.
        if (_tokenId == 0) {
            return "data:application/json;base64,eyJuYW1lIjoiRmVybWF0IiwiZGVzY3JpcHRpb24iOiJMb25nZX"
            "N0IHVuc29sdmVkIHB1enpsZS4iLCJpbWFnZV9kYXRhIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4y"
            "WnlCM2FXUjBhRDBpTlRVd0lpQm9aV2xuYUhROUlqVTFNQ0lnZG1sbGQwSnZlRDBpTUNBd0lEVTFNQ0ExTlRBaU"
            "lHWnBiR3c5SW01dmJtVWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SStQ"
            "SEJoZEdnZ1ptbHNiRDBpSXpFNE1VVXlPQ0lnWkQwaVRUQWdNR2czTlRCMk56VXdTREI2SWk4K1BISmxZM1FnZU"
            "QwaU1UUXpJaUI1UFNJMk9TSWdkMmxrZEdnOUlqSTJOQ0lnYUdWcFoyaDBQU0kwTVRJaUlISjRQU0k0SWlCbWFX"
            "eHNQU0lqTWpjek1ETkVJaTgrUEhKbFkzUWdlRDBpTVRRM0lpQjVQU0kzTXlJZ2MzUnliMnRsUFNJak1UQXhNek"
            "ZESWlCM2FXUjBhRDBpTWpVMklpQm9aV2xuYUhROUlqUXdOQ0lnY25nOUlqUWlJR1pwYkd3OUlpTXdaREV3TVRj"
            "aUx6NDhMM04yWno0PSJ9";
        }

        // Retrieve information about the puzzle.
        uint32 _puzzleId = uint32(_tokenId >> 128);
        PuzzleData memory puzzleData = getPuzzle[_puzzleId];
        address author = getPuzzleAuthor[_puzzleId];
        uint32 solves = getPuzzleColorsAndSolves[_puzzleId].solves;
        uint120 colors = getPuzzleColorsAndSolves[_puzzleId].colors;

        // Phase 0 if
        // `tokenData.solveTimestamp == puzzleData.firstSolveTimestamp`
        // Phase 1 if
        // `tokenData.solveTimestamp == puzzleData.firstSolveTimestamp + PHASE_ONE_LENGTH`
        // Phase 2 if
        // `tokenData.solveTimestamp == puzzleData.firstSolveTimestamp + SUBMISSION_LENGTH`
        uint8 phase = tokenData.solveTimestamp == puzzleData.firstSolveTimestamp
            ? 0
            : tokenData.solveTimestamp < puzzleData.firstSolveTimestamp + PHASE_ONE_LENGTH ? 1 : 2;

        return flagRenderer.render({
            _puzzleData: puzzleData,
            _tokenId: _tokenId + 1, // [MIGRATION] Increment to get rank.
            _author: author,
            _solveTime: tokenData.solveTimestamp - puzzleData.addedTimestamp,
            _solveMetadata: tokenData.solveMetadata,
            _phase: phase,
            _solves: solves,
            _colors: colors
        });
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// @notice Computes the phase the puzzle was at at some timestamp.
    /// @param _firstSolveTimestamp The timestamp of the first solve.
    /// @param _solveTimestamp The timestamp of the solve.
    /// @return phase The phase of the puzzle: ``Phase 0'' refers to the period
    /// before the puzzle has been solved, ``Phase 1'' refers to the period 2
    /// days after the first solve, ``Phase 2'' refers to the period 3 days
    /// after the end of ``Phase 1,'' and ``Phase 3'' is when submissions are
    /// closed.
    function _computePhase(uint40 _firstSolveTimestamp, uint40 _solveTimestamp)
        internal
        pure
        returns (uint8 phase)
    {
        // Equivalent to:
        // ```sol
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
        // ```
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
