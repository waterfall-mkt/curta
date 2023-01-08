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

    /// @notice Test evesnts emitted and storage variable changes upon adding a
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
    // Setter Functions
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @notice Mints an Authorship Token to `_to` by acting as Curta.
    /// @param _to The address to mint the token to.
    function mintAuthorshipToken(address _to) internal {
        vm.prank(address(curta));

        authorshipToken.curtaMint(_to);

        vm.stopPrank();
    }
}
