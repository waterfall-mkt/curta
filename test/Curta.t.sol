// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "./utils/BaseTest.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { ICurta } from "@/interfaces/ICurta.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { MockPuzzle } from "@/utils/mock/MockPuzzle.sol";

/// @notice Unit tests for `CurtaTest`, organized by functions.
/// @author fiveoutofnine
contract CurtaTest is BaseTest {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The length of "Phase 1" in seconds.
    /// @dev Copied from {Curta}.
    uint256 constant PHASE_ONE_LENGTH = 2 days;

    /// @notice The length of "Phase 1" and "Phase 2" combined (i.e. the solving
    /// period) in seconds.
    /// @dev Copied from {Curta}.
    uint256 constant SUBMISSION_LENGTH = 5 days;

    /// @notice The fee required to submit a solution during "Phase 2".
    /// @dev Copied from {Curta}.
    uint256 constant PHASE_TWO_FEE = 0.01 ether;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a puzzle is added.
    /// @dev Copied from {ICurta}.
    /// @param id The ID of the puzzle.
    /// @param author The address of the puzzle author.
    /// @param puzzle The address of the puzzle.
    event PuzzleAdded(uint32 indexed id, address indexed author, IPuzzle puzzle);

    /// @notice Emitted when a puzzle's token renderer is updated.
    /// @dev Copied from {ICurta}.
    /// @param id The ID of the puzzle.
    /// @param tokenRenderer The token renderer.
    event PuzzleTokenRendererUpdated(uint32 indexed id, ITokenRenderer tokenRenderer);

    /// @notice Emitted when a puzzle is solved.
    /// @dev Copied from {ICurta}.
    /// @param id The ID of the puzzle.
    /// @param solver The address of the solver.
    /// @param solution The solution.
    /// @param phase The phase in which the puzzle was solved.
    event PuzzleSolved(uint32 indexed id, address indexed solver, uint256 solution, uint8 phase);

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
    // `addPuzzle`
    // -------------------------------------------------------------------------

    /// @notice Test that sender must own an unused Authorship Token to add a
    /// puzzle.
    function test_addPuzzle_AuthorshipTokenOwnership() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(0xBEEF));

        // `address(this)` does not own Authorship Token #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.addPuzzle(IPuzzle(puzzle), 1);
    }

    /// @notice Test that sender may only use an Authorship Token once.
    function test_addPuzzle_UseAuthorshipTokenTwice() public {
        MockPuzzle puzzleOne = new MockPuzzle();
        MockPuzzle puzzleTwo = new MockPuzzle();
        _mintAuthorshipToken(address(this));

        // Should be able to add puzzle #1.
        curta.addPuzzle(IPuzzle(puzzleOne), 1);

        // Authorship Token #1 has been used already.
        vm.expectRevert(abi.encodeWithSelector(ICurta.AuthorshipTokenAlreadyUsed.selector, 1));
        curta.addPuzzle(IPuzzle(puzzleTwo), 1);
    }

    /// @notice Test that an Authorship Token is marked used after a puzzle is
    /// added with it.
    function test_addPuzzle_AuthorshipTokenMarkedUsed() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));

        // Authorship Token #1 has not been used yet.
        assertTrue(!curta.hasUsedAuthorshipToken(1));

        // Should be able to add puzzle #1.
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Authorship Token #1 has been used yet.
        assertTrue(curta.hasUsedAuthorshipToken(1));
    }

    /// @notice Test events emitted and storage variable changes upon adding a
    /// puzzle.
    function test_addPuzzle() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));

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
    // `solve`
    // -------------------------------------------------------------------------

    /// @notice Test that a player may only solve a puzzle once.
    function test_solve_SolveTwice() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
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
    function test_solve_NonExistantPuzzle(uint32 _puzzleId) public {
        // Puzzle #1 does not exist.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleDoesNotExist.selector, _puzzleId));
        curta.solve(_puzzleId, 0);
    }

    /// @notice Test that players may not submit solutions `SUBMISSION_LENGTH`<
    /// days after first blood.
    /// @param _secondsPassed The number of seconds that have passed since first
    /// blood.
    function test_solve_SubmitDuringPhase3(uint40 _secondsPassed) public {
        // Phase 3 starts after more than `SUBMISSION_LENGTH` days have passed
        // after first blood.
        vm.assume(
            _secondsPassed > SUBMISSION_LENGTH
                && _secondsPassed < (type(uint40).max - block.timestamp)
        );

        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
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
    function test_solve_SubmitIncorrectSolution(uint256 _submission) public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Ensure that `_submission` is invalid.
        vm.assume(_submission != puzzle.getSolution(address(this)));

        // `address(this)` submits an incorrect solution.
        vm.expectRevert(ICurta.IncorrectSolution.selector);
        curta.solve(1, _submission);
    }

    /// @notice Test whether the first solve timestamp is set to the timestamp
    /// the puzzle was solved in.
    function test_solve_FirstSolveTimestampSetOnFirstBlood(uint40 _timestamp) public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
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
    function test_solve_FirstSolveTimestampOnlySetOnFirstBlood(uint40 _secondsPassed) public {
        // We ignore timestamps that will cause an overflow or result in phase
        // 3.
        vm.assume(
            _secondsPassed <= SUBMISSION_LENGTH
                && _secondsPassed < (type(uint40).max - uint40(block.timestamp))
        );

        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(0xBEEF));
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
        curta.solve{value: PHASE_TWO_FEE}(1, solution);
        (,, uint40 firstSolveTimestamp) = curta.getPuzzle(1);

        assertEq(firstSolveTimestamp, timestamp);
    }

    /// @notice Test whether an Authorship Token is minted to the first solver
    /// of a puzzle.
    function test_solve_FirstBloodMintsAuthorshipToken() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
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
    function test_solve_PlayerMarkedAsSolved() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` has not solved Puzzle #1 yet.
        assertTrue(!curta.hasSolvedPuzzle(address(this), 1));

        curta.solve(1, puzzle.getSolution(address(this)));

        // `address(this)` has solved Puzzle #1.
        assertTrue(curta.hasSolvedPuzzle(address(this), 1));
    }

    /// @notice Test whether a Flag NFT is minted after a solve.
    function test_solve_MintFlagFromSolve() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` owns 0 Flag NFTs.
        assertEq(curta.balanceOf(address(this)), 0);

        curta.solve(1, puzzle.getSolution(address(this)));

        // `address(this)` now owns Flag NFT #`(1 << 128) | 0`.
        assertEq(curta.balanceOf(address(this)), 1);
        assertEq(curta.ownerOf((1 << 128) | 0), address(this));
    }

    /// @notice Test whether a puzzle's solves counter is updated.
    function test_solve_SolveCountersUpdated() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` gets first blood.
        curta.solve(1, puzzle.getSolution(address(this)));

        {
            (uint32 phase1Solves, uint32 phase2Solves, uint32 solves) = curta.getPuzzleSolves(1);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 1);
        }

        // `0xBEEF` gets a phase 1 solve.
        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve(1, beefSolution);

        {
            (uint32 phase1Solves, uint32 phase2Solves, uint32 solves) = curta.getPuzzleSolves(1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 0);
            assertEq(solves, 2);
        }

        vm.warp(block.timestamp + PHASE_ONE_LENGTH + 1);
        // `0xC0FFEE` gets a phase 2 solve.
        uint256 coffeeSolution = puzzle.getSolution(address(0xC0FFEE));
        vm.prank(address(0xC0FFEE));
        curta.solve{value: PHASE_TWO_FEE}(1, coffeeSolution);

        {
            (uint32 phase1Solves, uint32 phase2Solves, uint32 solves) = curta.getPuzzleSolves(1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 1);
            assertEq(solves, 3);
        }
    }

    /// @notice Test whether an ETH amount is required to solve a puzzle during
    /// phase 2.
    /// @param _payment The ETH amount sent via `solve()` during a phase 2
    /// solve.
    function test_solve_Phase2RequireETH(uint256 _payment) public {
        vm.assume(_payment <= 100 ether);

        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` gets first blood.
        curta.solve(1, puzzle.getSolution(address(this)));

        vm.warp(block.timestamp + PHASE_ONE_LENGTH + 1);

        // `0xBEEF` submits during phase 2.
        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        if (_payment < PHASE_TWO_FEE) vm.expectRevert(ICurta.InsufficientFunds.selector);
        curta.solve{value: _payment}(1, beefSolution);
    }

    /// @notice Test whether the ETH amount sent to solve a puzzle during phase
    /// 2 is paid out to the author.
    /// @dev Since this is during phase 1, there is no minimum requirement.
    /// Regardless, the author should still receive the ETH amount sent.
    /// @param _payment The ETH amount sent via `solve()` during a phase 1
    /// solve.
    function test_solve_Phase1PaymentPaidOutToAuthor(uint256 _payment) public {
        vm.assume(_payment >= PHASE_TWO_FEE && _payment <= 100 ether);

        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` gets first blood.
        curta.solve(1, puzzle.getSolution(address(this)));

        vm.warp(block.timestamp + 1 days + 1);

        // `address(this)` is the author of puzzle #1.
        uint256 authorBalance = address(this).balance;

        // `0xBEEF` submits during phase 2.
        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve{value: _payment}(1, beefSolution);

        // `address(this)` should have received the full payment.
        assertEq(address(this).balance, authorBalance + _payment);
    }

    /// @notice Test whether the ETH amount sent to solve a puzzle during phase
    /// 2 is paid out to the author.
    /// @dev The amount should be fully transferred to the author.
    /// {Curta-PHASE_TWO_FEE} is just a minimum requirement.
    /// @param _payment The ETH amount sent via `solve()` during a phase 2
    /// solve.
    function test_solve_Phase2PaymentPaidOutToAuthor(uint256 _payment) public {
        vm.assume(_payment >= PHASE_TWO_FEE && _payment <= 100 ether);

        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `address(this)` gets first blood.
        curta.solve(1, puzzle.getSolution(address(this)));

        vm.warp(block.timestamp + PHASE_ONE_LENGTH + 1);

        // `address(this)` is the author of puzzle #1.
        uint256 authorBalance = address(this).balance;

        // `0xBEEF` submits during phase 2.
        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve{value: _payment}(1, beefSolution);

        // `address(this)` should have received the full payment.
        assertEq(address(this).balance, authorBalance + _payment);
    }

    /// @notice Test events emitted and storage variable changes upon solving a
    /// puzzle in phases 0, 1, and 2.
    function test_solve() public {
        uint40 start = uint40(block.timestamp);
        uint40 firstBloodTimestamp;
        uint256 authorBalance = address(this).balance;

        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // `addedTimestamp` should be unaffected, and `firstSolveTimestamp`
        // should not be set yet.
        {
            (, uint40 addedTimestamp, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
            assertEq(addedTimestamp, start);
            assertEq(firstSolveTimestamp, 0);
        }

        // `address(this)` has not solved the puzzle yet.
        assertTrue(!curta.hasSolvedPuzzle(address(this), 1));

        uint256 solution = puzzle.getSolution(address(this));
        vm.expectEmit(true, true, true, true);
        emit PuzzleSolved({id: 1, solver: address(this), solution: solution, phase: 0});
        // `address(this)` gets first blood.
        curta.solve(1, solution);

        {
            (uint32 phase1Solves, uint32 phase2Solves, uint32 solves) = curta.getPuzzleSolves(1);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 1);

            (, uint40 addedTimestamp, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
            assertEq(addedTimestamp, start);
            assertEq(firstSolveTimestamp, start);
            firstBloodTimestamp = uint40(block.timestamp);

            assertTrue(curta.hasSolvedPuzzle(address(this), 1));

            // Authorship Token #2 should have been minted to `address(this)`.
            assertEq(authorshipToken.balanceOf(address(this)), 2);
            assertEq(authorshipToken.ownerOf(2), address(this));

            // `address(this)` now owns Flag NFT #`(1 << 128) | 0`.
            assertEq(curta.balanceOf(address(this)), 1);
            assertEq(curta.ownerOf((1 << 128) | 0), address(this));
        }

        vm.warp(firstBloodTimestamp + 0.5 days);

        // `address(0xBEEF)` has not solved the puzzle yet.
        assertTrue(!curta.hasSolvedPuzzle(address(0xBEEF), 1));

        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.expectEmit(true, true, true, true);
        emit PuzzleSolved({id: 1, solver: address(0xBEEF), solution: beefSolution, phase: 1});
        // `0xBEEF` gets a phase 1 solve.
        vm.prank(address(0xBEEF));
        curta.solve(1, beefSolution);

        {
            (uint32 phase1Solves, uint32 phase2Solves, uint32 solves) = curta.getPuzzleSolves(1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 0);
            assertEq(solves, 2);

            // Both `addedTimestamp` and `firstSolveTimestamp` should not have
            // been affected.
            (, uint40 addedTimestamp, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
            assertEq(addedTimestamp, start);
            assertEq(firstSolveTimestamp, start);
            assertEq(firstSolveTimestamp, firstBloodTimestamp);

            assertTrue(curta.hasSolvedPuzzle(address(0xBEEF), 1));

            // No Authorship Token should have been minted to `0xBEEF`.
            assertEq(authorshipToken.balanceOf(address(0xBEEF)), 0);

            // `0xBEEF` now owns Flag NFT #`(1 << 128) | 1`.
            assertEq(curta.balanceOf(address(0xBEEF)), 1);
            assertEq(curta.ownerOf((1 << 128) | 1), address(0xBEEF));
        }

        vm.warp(firstBloodTimestamp + PHASE_ONE_LENGTH + 1);

        // `address(0xC0FFEE)` has not solved the puzzle yet.
        assertTrue(!curta.hasSolvedPuzzle(address(0xC0FFEE), 1));

        uint256 coffeeSolution = puzzle.getSolution(address(0xC0FFEE));
        vm.expectEmit(true, true, true, true);
        emit PuzzleSolved({id: 1, solver: address(0xC0FFEE), solution: coffeeSolution, phase: 2});
        // `0xC0FFEE` gets a phase 2 solve.
        vm.prank(address(0xC0FFEE));
        curta.solve{value: PHASE_TWO_FEE}(1, coffeeSolution);

        {
            (uint32 phase1Solves, uint32 phase2Solves, uint32 solves) = curta.getPuzzleSolves(1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 1);
            assertEq(solves, 3);

            assertTrue(curta.hasSolvedPuzzle(address(0xC0FFEE), 1));

            // Both `addedTimestamp` and `firstSolveTimestamp` should not have
            // been affected.
            (, uint40 addedTimestamp, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
            assertEq(addedTimestamp, start);
            assertEq(firstSolveTimestamp, start);
            assertEq(firstSolveTimestamp, firstBloodTimestamp);

            // No Authorship Token should have been minted to `0xC0FFEE`.
            assertEq(authorshipToken.balanceOf(address(0xC0FFEE)), 0);

            // `0xC0FFEE` now owns Flag NFT #`(1 << 128) | 2`.
            assertEq(curta.balanceOf(address(0xC0FFEE)), 1);
            assertEq(curta.ownerOf((1 << 128) | 2), address(0xC0FFEE));
        }

        // Funds were transferred during `0xC0FFEE`'s phase 2 solve to the
        // author.
        assertEq(address(this).balance, authorBalance + PHASE_TWO_FEE);
    }

    // -------------------------------------------------------------------------
    // `setPuzzleTokenRenderer`
    // -------------------------------------------------------------------------

    /// @notice Test that sender is the author of the puzzle they are trying to
    /// update.
    function test_setPuzzleTokenRenderer_Unauthorized() public {
        ITokenRenderer tokenRenderer = new BaseRenderer();
        _deployAndAddPuzzle(address(0xBEEF));

        // `address(this)` is not the author of puzzle #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.setPuzzleTokenRenderer(1, tokenRenderer);
    }

    /// @notice Test events emitted and storage variable changes upon setting a
    /// new puzzle token renderer.
    function test_setPuzzleTokenRenderer() public {
        ITokenRenderer tokenRenderer = new BaseRenderer();
        _deployAndAddPuzzle(address(this));

        // Token renderer should be `address(0)` by default.
        assertEq(address(curta.getPuzzleTokenRenderer(1)), address(0));

        vm.expectEmit(true, true, true, true);
        emit PuzzleTokenRendererUpdated(1, tokenRenderer);
        curta.setPuzzleTokenRenderer(1, tokenRenderer);

        assertEq(address(curta.getPuzzleTokenRenderer(1)), address(tokenRenderer));
    }

    // -------------------------------------------------------------------------
    // `setFermat`
    // -------------------------------------------------------------------------

    /// @notice Test that a puzzle requires a solve before it can be set Fermat.
    function test_setFermat_PuzzleNotSolved() public {
        _deployAndAddPuzzle(address(this));

        // Puzzle #1 has not been solved yet.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleNotSolved.selector, 1));
        curta.setFermat(1);
    }

    /// @notice Test that a puzzle can be set Fermat as soon as there is a
    /// solve, even if there was no prior `fermat` set.
    function test_setFermat_InitialSet() public {
        vm.expectRevert("NOT_MINTED");
        curta.ownerOf(0);

        _deployAndAddPuzzle(address(0xBEEF));
        vm.warp(block.timestamp + 1 days);
        _solveMockPuzzle({_puzzleId: 1, _as: address(0xC0FFEE)});
        curta.setFermat(1);

        assertEq(curta.ownerOf(0), address(0xBEEF));
        assertEq(curta.balanceOf(address(0xBEEF)), 1);
        (uint32 puzzleId, uint40 timeTaken) = curta.fermat();
        assertEq(puzzleId, 1);
        assertEq(timeTaken, 1 days);
    }

    /// @notice Test that anybody can set Fermat.
    /// @param _sender The address to call `setFermat` from.
    function test_setFermat_Access(address _sender) public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({_puzzleId: 1, _as: address(this)});

        vm.prank(_sender);
        curta.setFermat(1);
    }

    /// @notice Test that a puzzle that is already set Fermat can not be set
    /// Fermat again.
    function test_setFermat_PuzzleAlreadyFermat() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({_puzzleId: 1, _as: address(this)});
        curta.setFermat(1);

        // Puzzle #1 has already been Fermat.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleAlreadyFermat.selector, 1));
        curta.setFermat(1);
    }

    /// @notice Test that a puzzle that did not take the longest to go unsolved
    ///  can not be set Fermat.
    function test_setFermat_PuzzleNotFermat() public {
        uint256 start = block.timestamp;

        // Add puzzle as ID #1, and solve it 2 days later.
        _deployAndAddPuzzle(address(this));
        vm.warp(start + 2 days);
        _solveMockPuzzle({_puzzleId: 1, _as: address(this)});
        curta.setFermat(1);

        // Add puzzle as ID #2, and solve it 1 day later. Since puzzle #1 took
        // longer to solve, puzzle #2 should not be eligible for Fermat.
        vm.warp(start);
        _deployAndAddPuzzle(address(this));
        vm.warp(start + 1 days);
        _solveMockPuzzle({_puzzleId: 2, _as: address(this)});
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleNotFermat.selector, 2));
        curta.setFermat(2);
    }

    /// @notice Test that the contract sets Fermat correctly, even if there was
    /// a previous Fermat set.
    function test_setFermat_SetTwice() public {
        uint256 start = block.timestamp;

        // Add puzzle as ID #1 from `0xBEEF`, and solve it 2 days later.
        _deployAndAddPuzzle(address(0xBEEF));
        vm.warp(start + 2 days);
        _solveMockPuzzle({_puzzleId: 1, _as: address(this)});

        // Add puzzle as ID #2 from `0xC0FEE`, and solve it 1 day later.
        vm.warp(start);
        _deployAndAddPuzzle(address(0xC0FFEE));
        vm.warp(start + 1 days);
        _solveMockPuzzle({_puzzleId: 2, _as: address(this)});

        // Although puzzle #2 took less time to solve, puzzle #1 was not set
        // Fermat, so puzzle #2 should be eligible for Fermat.
        curta.setFermat(2);

        // `0xC0FFEE` should own token #0.
        {
            assertEq(curta.ownerOf(0), address(0xC0FFEE));
            assertEq(curta.balanceOf(address(0xC0FFEE)), 1);
            (uint32 puzzleId, uint40 timeTaken) = curta.fermat();
            assertEq(puzzleId, 2);
            assertEq(timeTaken, 1 days);
        }

        // Puzzle #1 should also be eligible for Fermat.
        curta.setFermat(1);

        // Should have been transferred from `0xC0FFEE` to `0xBEEF`.
        {
            assertEq(curta.balanceOf(address(0xC0FFEE)), 0);
            assertEq(curta.ownerOf(0), address(0xBEEF));
            assertEq(curta.balanceOf(address(0xBEEF)), 1);
            (uint32 puzzleId, uint40 timeTaken) = curta.fermat();
            assertEq(puzzleId, 1);
            assertEq(timeTaken, 2 days);
        }
    }

    /// @notice Test that Fermat can still be set even if the initial author
    /// transfers the token.
    /// @param _to The address to transfer the token to.
    function test_setFermat_SetAfterTransfer(address _to) public {
        vm.assume(_to != address(0) && _to != address(0xC0FFEE));

        uint256 start = block.timestamp;

        // Add puzzle as ID #1 from `0xBEEF`, and solve it 2 days later.
        _deployAndAddPuzzle(address(0xBEEF));
        vm.warp(start + 2 days);
        _solveMockPuzzle({_puzzleId: 1, _as: address(this)});

        // Add puzzle as ID #2 from `0xC0FEE`, and solve it 1 day later.
        vm.warp(start);
        _deployAndAddPuzzle(address(0xC0FFEE));
        vm.warp(start + 1 days);
        _solveMockPuzzle({_puzzleId: 2, _as: address(this)});

        // Although puzzle #2 took less time to solve, puzzle #1 was not set
        // Fermat, so puzzle #2 should be eligible for Fermat.
        curta.setFermat(2);

        vm.prank(address(0xC0FFEE));

        // Transfer token #0.
        curta.transferFrom(address(0xC0FFEE), _to, 0);
        assertEq(curta.balanceOf(address(0xC0FFEE)), 0);
        assertEq(curta.ownerOf(0), _to);
        // `address(this)` should have a balance of 3 because it has 2
        // additional tokens from solving puzzles.
        assertEq(curta.balanceOf(_to), _to == address(this) ? 3 : 1);

        // Puzzle #1 should still be eligible for Fermat.
        curta.setFermat(1);

        // Should have been transferred from `_to` to `0xBEEF`.
        {
            assertEq(curta.ownerOf(0), address(0xBEEF));
            assertEq(curta.balanceOf(address(0xBEEF)), 1);
            (uint32 puzzleId, uint40 timeTaken) = curta.fermat();
            assertEq(puzzleId, 1);
            assertEq(timeTaken, 2 days);
        }
    }

    // -------------------------------------------------------------------------
    // `tokenURI`
    // -------------------------------------------------------------------------

    /// @notice Test that `tokenURI` reverts for nonexistant tokens.
    function test_tokenURI_UnmintedToken() public {
        vm.expectRevert("NOT_MINTED");
        authorshipToken.tokenURI(1);
    }

    // -------------------------------------------------------------------------
    // Miscellaneous
    // -------------------------------------------------------------------------

    /// @dev We add this so `address(this)` can receive funds for testing.
    receive() external payable { }
}
