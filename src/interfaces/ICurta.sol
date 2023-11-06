// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPuzzle } from "./IPuzzle.sol";
import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { FlagRenderer } from "@/contracts/FlagRenderer.sol";

/// @title The interface for Curta
/// @notice A CTF protocol, where players create and solve EVM puzzles to earn
/// NFTs.
/// @dev Each solve is represented by an NFT. However, the NFT with token ID 0
/// is reserved to denote ``Fermat''—the author's whose puzzle went the longest
/// unsolved.
interface ICurta {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when an Authorship Token has already been used to add a
    /// puzzle to Curta.
    /// @param _tokenId The ID of an Authorship Token.
    error AuthorshipTokenAlreadyUsed(uint256 _tokenId);

    /// @notice Emitted when a puzzle's solution is incorrect.
    error IncorrectSolution();

    /// @notice Emitted when insufficient funds are sent during "Phase 2"
    /// submissions.
    error InsufficientFunds();

    /// @notice Emitted when a puzzle is already marked as Fermat.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleAlreadyFermat(uint32 _puzzleId);

    /// @notice Emitted when a solver has already solved a puzzle.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleAlreadySolved(uint32 _puzzleId);

    /// @notice Emitted when a puzzle does not exist.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleDoesNotExist(uint32 _puzzleId);

    /// @notice Emitted when a puzzle is the zero address or the Curta address.
    error PuzzleInvalidAddress();

    /// @notice Emitted when the puzzle was not the one that went longest
    /// unsolved.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleNotFermat(uint32 _puzzleId);

    /// @notice Emitted when a puzzle has a zero-length name.
    error PuzzleNotNamed();

    /// @notice Emitted when a puzzle has not been solved yet.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleNotSolved(uint32 _puzzleId);

    /// @notice Emitted when submissions for a puzzle is closed.
    /// @param _puzzleId The ID of a puzzle.
    error SubmissionClosed(uint32 _puzzleId);

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice A struct containing data about the puzzle corresponding to
    /// Fermat (i.e. the puzzle that went the longest unsolved).
    /// @param puzzleId The ID of the puzzle.
    /// @param timeTaken The number of seconds it took to first solve the
    /// puzzle.
    struct Fermat {
        uint32 puzzleId;
        uint40 timeTaken;
    }

    /// @notice A struct containing data about a puzzle.
    /// @param puzzle The address of the puzzle.
    /// @param addedTimestamp The timestamp at which the puzzle was added.
    /// @param firstSolveTimestamp The timestamp at which the first valid
    /// solution was submitted.
    struct PuzzleData {
        IPuzzle puzzle;
        uint40 addedTimestamp;
        uint40 firstSolveTimestamp;
    }

    /// @notice A struct containing the number of solves a puzzle has.
    /// @param colors A bitpacked `uint120` of 5 24-bit colors for the puzzle's
    /// Flags in the following order (left-to-right):
    ///     * Background color
    ///     * Fill color
    ///     * Border color
    ///     * Primary text color
    ///     * Secondary text color
    /// @param phase0Solves The total number of Phase 0 solves a puzzle has.
    /// @param phase1Solves The total number of Phase 1 solves a puzzle has.
    /// @param phase2Solves The total number of Phase 2 solves a puzzle has.
    /// @param solves The total number of solves a puzzle has.
    struct PuzzleColorsAndSolves {
        uint120 colors;
        uint32 phase0Solves;
        uint32 phase1Solves;
        uint32 phase2Solves;
        uint32 solves;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a puzzle is added.
    /// @param id The ID of the puzzle.
    /// @param author The address of the puzzle author.
    /// @param puzzle The address of the puzzle.
    event AddPuzzle(uint32 indexed id, address indexed author, IPuzzle puzzle);

    /// @notice Emitted when a puzzle is solved.
    /// @param id The ID of the puzzle.
    /// @param solver The address of the solver.
    /// @param solution The solution.
    /// @param phase The phase in which the puzzle was solved.
    event SolvePuzzle(uint32 indexed id, address indexed solver, uint256 solution, uint8 phase);

    /// @notice Emitted when a puzzle's colors are updated.
    /// @param id The ID of the puzzle.
    /// @param colors A bitpacked `uint120` of 5 24-bit colors for the puzzle's
    /// Flags.
    event UpdatePuzzleColors(uint32 indexed id, uint256 colors);

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @notice The Flag metadata and art renderer contract.
    function flagRenderer() external view returns (FlagRenderer);

    /// @return The Authorship Token contract.
    function authorshipToken() external view returns (AuthorshipToken);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @return The total number of puzzles.
    function puzzleId() external view returns (uint32);

    /// @return puzzleId The ID of the puzzle corresponding to Fermat.
    /// @return timeTaken The number of seconds it took to solve the puzzle.
    function fermat() external view returns (uint32 puzzleId, uint40 timeTaken);

    /// @param _puzzleId The ID of a puzzle.
    /// @return colors A bitpacked `uint120` of 5 24-bit colors for the puzzle's
    /// Flags.
    /// @return phase0Solves The total number of Phase 0 solves a puzzle has.
    /// @return phase1Solves The total number of Phase 1 solves a puzzle has.
    /// @return phase2Solves The total number of Phase 2 solves a puzzle has.
    /// @return solves The total number of solves a puzzle has.
    function getPuzzleColorsAndSolves(uint32 _puzzleId)
        external
        view
        returns (
            uint120 colors,
            uint32 phase0Solves,
            uint32 phase1Solves,
            uint32 phase2Solves,
            uint32 solves
        );

    /// @param _puzzleId The ID of a puzzle.
    /// @return puzzle The address of the puzzle.
    /// @return addedTimestamp The timestamp at which the puzzle was added.
    /// @return firstSolveTimestamp The timestamp at which the first solution
    /// was submitted.
    function getPuzzle(uint32 _puzzleId)
        external
        view
        returns (IPuzzle puzzle, uint40 addedTimestamp, uint40 firstSolveTimestamp);

    /// @param _puzzleId The ID of a puzzle.
    /// @return The address of the puzzle author.
    function getPuzzleAuthor(uint32 _puzzleId) external view returns (address);

    /// @param _solver The address of a solver.
    /// @param _puzzleId The ID of a puzzle.
    /// @return Whether `_solver` has solved the puzzle of ID `_puzzleId`.
    function hasSolvedPuzzle(address _solver, uint32 _puzzleId) external view returns (bool);

    /// @param _tokenId The ID of an Authorship Token.
    /// @return Whether the Authorship Token of ID `_tokenId` has been used to
    /// add a puzzle.
    function hasUsedAuthorshipToken(uint256 _tokenId) external view returns (bool);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a Flag NFT if the provided solution solves the puzzle.
    /// @param _puzzleId The ID of the puzzle.
    /// @param _solution The solution.
    function solve(uint32 _puzzleId, uint256 _solution) external payable;

    /// @notice Adds a puzzle to the contract. Note that an unused Authorship
    /// Token is required to add a puzzle (see {AuthorshipToken}).
    /// @param _puzzle The address of the puzzle.
    /// @param _id The ID of the Authorship Token to burn.
    function addPuzzle(IPuzzle _puzzle, uint256 _id) external;

    /// @notice Set the colors for a puzzle's Flags.
    /// @dev Only the author of the puzzle of ID `_puzzleId` may set its token
    /// renderer.
    /// @param _puzzleId The ID of the puzzle.
    /// @param _colors A bitpacked `uint120` of 5 24-bit colors for the puzzle's
    /// Flags.
    function setPuzzleColors(uint32 _puzzleId, uint120 _colors) external;

    /// @notice Burns and mints NFT #0 to the author of the puzzle of ID
    /// `_puzzleId` if it is the puzzle that went longest unsolved.
    /// @dev The puzzle of ID `_puzzleId` must have been solved at least once.
    /// @param _puzzleId The ID of the puzzle.
    function setFermat(uint32 _puzzleId) external;
}
