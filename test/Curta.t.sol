// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import { AuthorshipToken } from "@/AuthorshipToken.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { Curta } from "@/Curta.sol";
import { ICurta } from "@/interfaces/ICurta.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { CollatzPuzzle } from "@/utils/mock/CollatzPuzzle.sol";
import { LibRLP } from "@/utils/LibRLP.sol";

contract CurtaTest is Test {
    BaseRenderer internal tokenRenderer;
    AuthorshipToken internal authorshipToken;
    Curta internal curta;

    // -------------------------------------------------------------------------
    // Events (NOTE: copied from {ICurta})
    // -------------------------------------------------------------------------

    /// @notice Emitted when a puzzle is added.
    /// @param id The ID of the puzzle.
    /// @param author The address of the puzzle author.
    /// @param puzzle The address of the puzzle.
    event PuzzleAdded(uint32 indexed id, address indexed author, IPuzzle puzzle);

    /// @notice Emitted when a puzzle's token renderer is updated.
    /// @param id The ID of the puzzle.
    /// @param tokenRenderer The token renderer.
    event PuzzleTokenRendererUpdated(uint32 indexed id, ITokenRenderer tokenRenderer);

    /// @notice Emitted when a puzzle is solved.
    /// @param id The ID of the puzzle.
    /// @param solver The address of the solver.
    /// @param solution The solution.
    /// @param phase The phase in which the puzzle was solved.
    event PuzzleSolved(uint32 indexed id, address indexed solver, uint256 solution, uint8 phase);

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        tokenRenderer = new BaseRenderer();

        address authorshipTokenAddress = LibRLP.computeAddress(address(this), 2);
        address curtaAddress = LibRLP.computeAddress(address(this), 3);

        authorshipToken = new AuthorshipToken(curtaAddress, "");

        curta = new Curta(ITokenRenderer(address(tokenRenderer)), authorshipToken);
    }

    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    /// @notice Test that `Curta` and `AuthorshipToken` stored each other's
    /// addresses properly.
    function testCheckDeployAddresses() public {
        assertEq(address(authorshipToken.curta()), address(curta));
        assertEq(address(curta.authorshipToken()), address(authorshipToken));
    }

    // -------------------------------------------------------------------------
    // Add Puzzle
    // -------------------------------------------------------------------------

    /// @notice Test that sender must own an unused Authorship Token to add a
    /// puzzle.
    function testAddPuzzleAuthorshipTokenOwnership() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(0xBEEF));

        // `address(this)` does not own Authorship Token #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.addPuzzle(IPuzzle(puzzle), 1);
    }

    /// @notice Test that sender may only use an Authorship Token once.
    function testUseAuthorshipTokenTwice() public {
        CollatzPuzzle puzzleOne = new CollatzPuzzle();
        CollatzPuzzle puzzleTwo = new CollatzPuzzle();
        mintAuthorshipToken(address(this));

        // Should be able to add puzzle #1.
        curta.addPuzzle(IPuzzle(puzzleOne), 1);

        // Authorship Token #1 has been used already.
        vm.expectRevert(abi.encodeWithSelector(ICurta.AuthorshipTokenAlreadyUsed.selector, 1));
        curta.addPuzzle(IPuzzle(puzzleTwo), 1);
    }

    /// @notice Test that an Authorship Token is marked used after a puzzle is
    /// added with it.
    function testAuthorshipTokenMarkedUsed() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));

        // Authorship Token #1 has not been used yet.
        assertTrue(!curta.hasUsedAuthorshipToken(1));

        // Should be able to add puzzle #1.
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Authorship Token #1 has been used yet.
        assertTrue(curta.hasUsedAuthorshipToken(1));
    }

    /// @notice Test events emitted and storage variable changes upon adding a
    /// puzzle.
    function testAddPuzzle() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));

        // There are 0 puzzles.
        assertEq(curta.puzzleId(), 0);

        // Should be able to add puzzle #1.
        vm.expectEmit(true, true, true, true);
        emit PuzzleAdded(1, address(this), IPuzzle(puzzle));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // There is 1 puzzle.
        assertEq(curta.puzzleId(), 1);
        assertEq(curta.getPuzzleAuthor(1), address(this));

        (IPuzzle addedPuzzle, uint40 addedTimestamp, uint40 firstSolveTimestamp) =
            curta.getPuzzle(1);
        assertEq(address(addedPuzzle), address(puzzle));
        assertEq(addedTimestamp, uint40(block.timestamp));
        // There have been no solves.
        assertEq(firstSolveTimestamp, 0);
    }

    // -------------------------------------------------------------------------
    // Solve Puzzle
    // -------------------------------------------------------------------------

    /// @notice Test that a player may only solve a puzzle once.
    function testSolvePuzzleTwice() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Should be able to solve puzzle #1.
        uint256 solution = puzzle.getSolution(address(this));
        curta.solve(1, solution);

        // `address(this)` has already solved Puzzle #1.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleAlreadySolved.selector, 1));
        curta.solve(1, solution);
    }

    /// @notice Test that players may only submit solutions to puzzles that
    /// exist.
    /// @param _puzzleId The ID of the puzzle.
    function testSolveNonExistantPuzzle(uint32 _puzzleId) public {
        // Puzzle #1 does not exist.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleDoesNotExist.selector, _puzzleId));
        curta.solve(_puzzleId, 0);
    }

    /// @notice Test that players may not submit solutions 5< days after first
    /// blood.
    /// @param _secondsPassed The number of seconds that have passed since first
    /// blood.
    function testSubmitDuringPhase3(uint256 _secondsPassed) public {
        // Phase 3 starts after more than 5 days have passed after first blood.
        vm.assume(_secondsPassed > 5 days && _secondsPassed < (type(uint256).max - block.timestamp));

        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `0xBEEF` gets first blood.
        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve(1, beefSolution);

        // Warp to phase 3.
        vm.warp(block.timestamp + _secondsPassed);
        uint256 solution = puzzle.getSolution(address(this));
        vm.expectRevert(abi.encodeWithSelector(ICurta.SubmissionClosed.selector, uint32(1)));
        curta.solve(1, solution);
    }

    /// @notice Test submitting an incorrect solution.
    /// @param _submission A submission.
    function testSubmitIncorrectSolution(uint256 _submission) public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Ensure that `_submission` is invalid.
        vm.assume(_submission != puzzle.getSolution(address(this)));

        // `address(this)` submits an incorrect solution.
        vm.expectRevert(ICurta.IncorrectSolution.selector);
        curta.solve(1, _submission);
    }

    /// @notice Test whether the first solve timestamp is set to the timestamp
    /// the puzzle was solved in.
    function testFirstSolveTimestampSetOnFirstBlood(uint40 _timestamp) public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Warp to `_timestamp`.
        vm.warp(_timestamp);

        // `address(this)` gets first blood.
        uint256 solution = puzzle.getSolution(address(this));
        curta.solve(1, solution);

        // The first solve timestamp is set to `_timestamp`.
        (,, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
        assertEq(firstSolveTimestamp, _timestamp);
    }

    /// @notice Test that the first solve timestamp is not set on any secondary
    /// solves, no matter how far into the future.
    /// @param _secondsPassed The number of seconds that have passed since first
    /// blood.
    function testFirstSolveTimestampOnlySetOnFirstBlood(uint40 _secondsPassed) public {
        // We ignore timestamps that will cause an overflow or result in phase
        // 3.
        vm.assume(
            _secondsPassed <= 5 days
                && _secondsPassed < (type(uint40).max - uint40(block.timestamp))
        );

        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(0xBEEF));
        vm.prank(address(0xBEEF));
        // Add puzzle as `0xBEEF`.
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `0xC0FFEE` gets first blood at `timestamp`.
        uint40 timestamp = uint40(block.timestamp);
        uint256 coffeeSolution = puzzle.getSolution(address(0xC0FFEE));
        vm.prank(address(0xC0FFEE));
        curta.solve(1, coffeeSolution);

        // Warp to `_secondsPassed` after first blood.
        vm.warp(timestamp + _secondsPassed);

        // `address(this)` gets their solve at `timestamp + _secondsPassed`.
        uint256 solution = puzzle.getSolution(address(this));
        curta.solve{value: 0.01 ether}(1, solution);
        (,, uint40 firstSolveTimestamp) = curta.getPuzzle(1);

        assertEq(firstSolveTimestamp, timestamp);
    }

    /// @notice Test whether an Authorship Token is minted to the first solver
    /// of a puzzle.
    function testFirstBloodMintsAuthorshipToken() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` has 1 Authorship Token.
        assertEq(authorshipToken.balanceOf(address(this)), 1);
        // Authorship Token #2 is not minted yet.
        vm.expectRevert("NOT_MINTED");
        authorshipToken.ownerOf(2);

        curta.solve(1, puzzle.getSolution(address(this)));

        // 1 more Authorship Token has been minted to `address(this)`.
        assertEq(authorshipToken.balanceOf(address(this)), 2);
        // Authorship Token #2 was minted to `address(this)`.
        assertEq(authorshipToken.ownerOf(2), address(this));
    }

    /// @notice Test whether Curta marks a player as having solved a puzzle.
    function testPlayerMarkedAsSolved() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` has not solved Puzzle #1 yet.
        assertTrue(!curta.hasSolvedPuzzle(address(this), 1));

        curta.solve(1, puzzle.getSolution(address(this)));

        // `address(this)` has solved Puzzle #1.
        assertTrue(curta.hasSolvedPuzzle(address(this), 1));
    }

    // -------------------------------------------------------------------------
    // Fermat
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Set Puzzle Token Renderer
    // -------------------------------------------------------------------------

    /// @notice Test that sender is the author of the puzzle they are trying to
    /// update.
    function testUnauthorizedSetPuzzleTokenRenderer() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        ITokenRenderer tokenRenderer = new BaseRenderer();
        mintAuthorshipToken(address(0xBEEF));

        vm.prank(address(0xBEEF));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` is not the author of puzzle #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.setPuzzleTokenRenderer(1, tokenRenderer);
    }

    /// @notice Test events emitted and storage variable changes upon setting a
    /// new puzzle token renderer.
    function testSetPuzzleTokenRenderer() public {
        CollatzPuzzle puzzle = new CollatzPuzzle();
        ITokenRenderer tokenRenderer = new BaseRenderer();
        mintAuthorshipToken(address(this));

        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Token renderer should be `address(0)` by default.
        assertEq(address(curta.getPuzzleTokenRenderer(1)), address(0));

        vm.expectEmit(true, true, true, true);
        emit PuzzleTokenRendererUpdated(1, tokenRenderer);
        curta.setPuzzleTokenRenderer(1, tokenRenderer);

        assertEq(address(curta.getPuzzleTokenRenderer(1)), address(tokenRenderer));
    }

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @notice Mints an Authorship Token to `_to` by acting as Curta.
    /// @param _to The address to mint the token to.
    function mintAuthorshipToken(address _to) internal {
        vm.prank(address(curta));

        authorshipToken.curtaMint(_to);
    }
}
