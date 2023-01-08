// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import { AuthorshipToken } from "@/AuthorshipToken.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { Curta } from "@/Curta.sol";
import { ICurta } from "@/interfaces/ICurta.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { MockPuzzle } from "@/utils/mock/MockPuzzle.sol";
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
        MockPuzzle puzzle = new MockPuzzle();
        mintAuthorshipToken(address(0xBEEF));

        // `address(this)` does not own Authorship Token #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.addPuzzle(IPuzzle(puzzle), 1);
    }

    /// @notice Test that sender may only use an Authorship Token once.
    function testUseAuthorshipTokenTwice() public {
        MockPuzzle puzzleOne = new MockPuzzle();
        MockPuzzle puzzleTwo = new MockPuzzle();
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
        MockPuzzle puzzle = new MockPuzzle();
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
        MockPuzzle puzzle = new MockPuzzle();
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

    // -------------------------------------------------------------------------
    // Fermat
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Set Puzzle Token Renderer
    // -------------------------------------------------------------------------

    /// @notice Test that sender is the author of the puzzle they are trying to
    /// update.
    function testUnauthorizedSetPuzzleTokenRenderer() public {
        MockPuzzle puzzle = new MockPuzzle();
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
        MockPuzzle puzzle = new MockPuzzle();
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
