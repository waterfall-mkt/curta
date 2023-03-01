// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "./utils/BaseTest.sol";
import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { IPuzzle } from "@/contracts/interfaces/IPuzzle.sol";
import { MockPuzzle } from "@/contracts/utils/mock/MockPuzzle.sol";

/// @notice Unit tests for `Curta`, organized by functions.
contract CurtaTest is BaseTest {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The length of Phase 1 in seconds.
    /// @dev Copied from {Curta}.
    uint256 constant PHASE_ONE_LENGTH = 2 days;

    /// @notice The length of Phase 1 and Phase 2 combined (i.e. the solving
    /// period) in seconds.
    /// @dev Copied from {Curta}.
    uint256 constant SUBMISSION_LENGTH = 5 days;

    /// @notice The minimum fee required to submit a solution during Phase 2.
    /// @dev Copied from {Curta}.
    uint256 constant PHASE_TWO_MINIMUM_FEE = 0.02 ether;

    /// @notice The protocol fee required to submit a solution during Phase 2.
    /// @dev Copied from {Curta}.
    uint256 constant PHASE_TWO_PROTOCOL_FEE = 0.01 ether;

    /// @notice The default Flag colors.
    /// @dev Copied from {Curta}.
    uint120 constant DEFAULT_FLAG_COLORS = 0x181E28181E2827303DF0F6FC94A3B3;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a puzzle is added.
    /// @dev Copied from {ICurta}.
    /// @param id The ID of the puzzle.
    /// @param author The address of the puzzle author.
    /// @param puzzle The address of the puzzle.
    event AddPuzzle(uint32 indexed id, address indexed author, IPuzzle puzzle);

    /// @dev Copied from EIP-721.
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    /// @dev Copied from EIP-721.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted when a puzzle is solved.
    /// @dev Copied from {ICurta}.
    /// @param id The ID of the puzzle.
    /// @param solver The address of the solver.
    /// @param solution The solution.
    /// @param phase The phase in which the puzzle was solved.
    event SolvePuzzle(uint32 indexed id, address indexed solver, uint256 solution, uint8 phase);

    /// @dev Copied from EIP-721.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @notice Emitted when a puzzle's colors are updated.
    /// @dev Copied from {ICurta}.
    /// @param id The ID of the puzzle.
    /// @param colors A bitpacked `uint120` of 5 24-bit colors for the puzzle's
    /// Flags.
    event UpdatePuzzleColors(uint32 indexed id, uint256 colors);

    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    /// @notice Test that `Curta` and `AuthorshipToken` stored each other's
    /// addresses properly.
    function test_Initialization_DeployAddressesMatch() public {
        assertEq(address(authorshipToken.curta()), address(curta));
        assertEq(address(curta.authorshipToken()), address(authorshipToken));
    }

    // -------------------------------------------------------------------------
    // `addPuzzle`
    // -------------------------------------------------------------------------

    /// @notice Test that sender must own an unused Authorship Token to add a
    /// puzzle.
    function test_addPuzzle_UseUnownedAuthorshipToken_RevertsUnauthorized() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(0xBEEF));

        // `address(this)` does not own Authorship Token #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.addPuzzle(IPuzzle(puzzle), 1);
    }

    /// @notice Test that sender may only use an Authorship Token once.
    function test_addPuzzle_UseSameAuthorshipTokenTwice_Fails() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));

        // Should be able to add puzzle #1.
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Authorship Token #1 has been used already.
        vm.expectRevert(abi.encodeWithSelector(ICurta.AuthorshipTokenAlreadyUsed.selector, 1));
        curta.addPuzzle(IPuzzle(puzzle), 1);
    }

    /// @notice Test that an Authorship Token is marked used after a puzzle is
    /// added with it.
    function test_addPuzzle_UseAuthorshipToken_UpdatesStorage() public {
        MockPuzzle puzzle = new MockPuzzle();
        _mintAuthorshipToken(address(this));

        // Authorship Token #1 has not been used yet.
        assertTrue(!curta.hasUsedAuthorshipToken(1));

        // Should be able to add puzzle #1.
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // Authorship Token #1 has been used.
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
        emit AddPuzzle(1, address(this), IPuzzle(puzzle));
        curta.addPuzzle(IPuzzle(puzzle), 1);

        // There is 1 puzzle.
        assertEq(curta.puzzleId(), 1);
        assertEq(curta.getPuzzleAuthor(1), address(this));

        // The puzzle's Flag colors are set to the default colors.
        (uint120 colors,,,,) = curta.getPuzzleColorsAndSolves(1);
        assertEq(colors, DEFAULT_FLAG_COLORS);

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
    function test_solve_SamePuzzleTwice_Fails() public {
        _deployAndAddPuzzle(address(this));

        // Should be able to solve puzzle #1.
        uint256 solution = mockPuzzle.getSolution(address(this));
        curta.solve(1, solution);

        // `address(this)` has already solved Puzzle #1.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleAlreadySolved.selector, 1));
        curta.solve(1, solution);
    }

    /// @notice Test that players may only submit solutions to puzzles that
    /// exist.
    function test_solve_NonExistantPuzzle_Fails() public {
        // Puzzle #1 does not exist.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleDoesNotExist.selector, 1));
        curta.solve({ _puzzleId: 1, _solution: 0 });
    }

    /// @notice Test that players may not submit solutions `SUBMISSION_LENGTH`<
    /// days after first blood.
    /// @param _secondsPassed The number of seconds that have passed since first
    /// blood.
    function test_solve_DuringPhase3_Fails(uint40 _secondsPassed) public {
        // Phase 3 starts after more than `SUBMISSION_LENGTH` days have passed
        // after first blood.
        vm.assume(
            _secondsPassed > SUBMISSION_LENGTH
                && _secondsPassed < (type(uint40).max - block.timestamp)
        );

        _deployAndAddPuzzle(address(this));

        // `0xBEEF` gets first blood.
        uint256 beefSolution = mockPuzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve(1, beefSolution);

        // Warp to Phase 3.
        vm.warp(block.timestamp + _secondsPassed);
        uint256 solution = mockPuzzle.getSolution(address(this));
        vm.expectRevert(abi.encodeWithSelector(ICurta.SubmissionClosed.selector, uint32(1)));
        curta.solve(1, solution);
    }

    /// @notice Test submitting an incorrect solution.
    /// @param _solution A solution attempt.
    function test_solve_IncorrectSolution_Fails(uint256 _solution) public {
        _deployAndAddPuzzle(address(this));

        // Ensure that `_solution` is incorrect.
        vm.assume(_solution != mockPuzzle.getSolution(address(this)));

        // `address(this)` submits an incorrect solution.
        vm.expectRevert(ICurta.IncorrectSolution.selector);
        curta.solve(1, _solution);
    }

    /// @notice Test whether the first solve timestamp is set to the timestamp
    /// the puzzle was solved in.
    function test_solve_FirstBlood_UpdatesFirstSolveTimestamp(uint40 _timestamp) public {
        _deployAndAddPuzzle(address(this));

        vm.warp(_timestamp);

        // `address(this)` gets first blood.
        uint256 solution = mockPuzzle.getSolution(address(this));
        curta.solve(1, solution);

        // The first solve timestamp is set to `_timestamp`.
        (,, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
        assertEq(firstSolveTimestamp, _timestamp);
    }

    /// @notice Test that a token can not be minted to `address(0)`.
    /// @dev This case will never happen as long as `authorshipToken` and
    /// `curta` correctly initialize each other's addresses at deploy, but we
    /// test for it anyway to achieve full coverage.
    function test_solve_FirstBlood_AuthorshipTokenMintPotentialRevertBranch() public {
        _deployAndAddPuzzle(address(this));

        uint256 solution = mockPuzzle.getSolution(address(0));

        // Can not mint an Authorship Token to `address(0)`.
        vm.prank(address(0));
        vm.expectRevert("INVALID_RECIPIENT");
        curta.solve(1, solution);
    }

    /// @notice Test that the first solve timestamp is not set on any secondary
    /// solves, no matter how far into the future.
    /// @param _secondsPassed The number of seconds that have passed since first
    /// blood.
    function test_solve_DuringAllPhases_FirstSolveTimestampOnlySetOnFirstBlood(
        uint40 _secondsPassed
    ) public {
        // We ignore timestamps that will cause an overflow or result in Phase
        // 3.
        vm.assume(
            _secondsPassed <= SUBMISSION_LENGTH
                && _secondsPassed < (type(uint40).max - uint40(block.timestamp))
        );

        _deployAndAddPuzzle(address(0xBEEF));

        // `0xC0FFEE` gets first blood at `timestamp`.
        uint40 timestamp = uint40(block.timestamp);
        uint256 coffeeSolution = mockPuzzle.getSolution(address(0xC0FFEE));
        vm.prank(address(0xC0FFEE));
        curta.solve(1, coffeeSolution);

        // Warp to `_secondsPassed` after first blood.
        vm.warp(timestamp + _secondsPassed);

        // `address(this)` gets their solve at `timestamp + _secondsPassed`.
        uint256 solution = mockPuzzle.getSolution(address(this));
        curta.solve{ value: PHASE_TWO_MINIMUM_FEE }(1, solution);
        (,, uint40 firstSolveTimestamp) = curta.getPuzzle(1);

        // `firstSolveTimestamp` remains unchanged.
        assertEq(firstSolveTimestamp, timestamp);
    }

    /// @notice Test whether an Authorship Token is minted to the first solver
    /// of a puzzle.
    function test_solve_FirstBlood_MintsAuthorshipToken() public {
        _deployAndAddPuzzle(address(this));

        // `address(this)` has 1 Authorship Token.
        assertEq(authorshipToken.balanceOf(address(this)), 1);
        // Authorship Token #2 is not minted yet.
        vm.expectRevert("NOT_MINTED");
        authorshipToken.ownerOf(2);

        curta.solve(1, mockPuzzle.getSolution(address(this)));

        // 1 more Authorship Token has been minted to `address(this)`.
        assertEq(authorshipToken.balanceOf(address(this)), 2);
        // Authorship Token #2 was minted to `address(this)`.
        assertEq(authorshipToken.ownerOf(2), address(this));
    }

    /// @notice Test whether Curta marks a player as having solved a puzzle.
    function test_solve_Success_UpdatesStorage() public {
        _deployAndAddPuzzle(address(this));

        // `address(this)` has not solved Puzzle #1 yet.
        assertTrue(!curta.hasSolvedPuzzle(address(this), 1));

        curta.solve(1, mockPuzzle.getSolution(address(this)));

        // `address(this)` has solved Puzzle #1.
        assertTrue(curta.hasSolvedPuzzle(address(this), 1));
    }

    /// @notice Test whether a Flag NFT is minted to the solver after a solve.
    function test_solve_Success_MintsFlag() public {
        _deployAndAddPuzzle(address(this));

        // `address(this)` owns 0 Flag NFTs.
        assertEq(curta.balanceOf(address(this)), 0);

        curta.solve(1, mockPuzzle.getSolution(address(this)));

        // `address(this)` now owns Flag NFT #`(1 << 128) | 0`.
        assertEq(curta.balanceOf(address(this)), 1);
        assertEq(curta.ownerOf((1 << 128) | 0), address(this));
    }

    /// @notice Test whether a puzzle's solves counter is updated.
    function test_solve_Success_UpdatesSolveCounters() public {
        _deployAndAddPuzzle(address(this));

        // `address(this)` gets first blood.
        curta.solve(1, mockPuzzle.getSolution(address(this)));
        {
            (, uint32 phase0Solves, uint32 phase1Solves, uint32 phase2Solves, uint32 solves) =
                curta.getPuzzleColorsAndSolves(1);
            assertEq(phase0Solves, 1);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 1);
        }

        // `0xBEEF` gets a Phase 1 solve.
        uint256 beefSolution = mockPuzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve(1, beefSolution);
        {
            (, uint32 phase0Solves, uint32 phase1Solves, uint32 phase2Solves, uint32 solves) =
                curta.getPuzzleColorsAndSolves(1);
            assertEq(phase0Solves, 1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 0);
            assertEq(solves, 2);
        }

        // Warp to Phase 2.
        vm.warp(block.timestamp + PHASE_ONE_LENGTH + 1);
        // `0xC0FFEE` gets a Phase 2 solve.
        uint256 coffeeSolution = mockPuzzle.getSolution(address(0xC0FFEE));
        vm.prank(address(0xC0FFEE));
        curta.solve{ value: PHASE_TWO_MINIMUM_FEE }(1, coffeeSolution);
        {
            (, uint32 phase0Solves, uint32 phase1Solves, uint32 phase2Solves, uint32 solves) =
                curta.getPuzzleColorsAndSolves(1);
            assertEq(phase0Solves, 1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 1);
            assertEq(solves, 3);
        }
    }

    /// @notice Test whether an ETH amount is required to solve a puzzle during
    /// Phase 2.
    /// @param _payment The ETH amount sent via `solve()` during a Phase 2
    /// solve.
    function test_solve_DuringPhase2_RequiresETH(uint256 _payment) public {
        vm.assume(_payment <= 100 ether);
        _deployAndAddPuzzle(address(this));

        // `address(this)` gets first blood.
        curta.solve(1, mockPuzzle.getSolution(address(this)));

        // Warp to Phase 2.
        vm.warp(block.timestamp + PHASE_ONE_LENGTH + 1);

        // `0xBEEF` submits during Phase 2, but below the minimum ETH
        // requirement.
        uint256 beefSolution = mockPuzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        if (_payment < PHASE_TWO_MINIMUM_FEE) vm.expectRevert(ICurta.InsufficientFunds.selector);
        curta.solve{ value: _payment }(1, beefSolution);
    }

    /// @notice Test whether the ETH amount sent to solve a puzzle during Phase
    /// 1 is paid out to the author.
    /// @dev Since this is during Phase 1, there is no minimum requirement.
    /// Regardless, the author should still receive the ETH amount sent.
    /// @param _payment The ETH amount sent via `solve()` during a Phase 1
    /// solve.
    function test_solve_DuringPhase1WithPayment_PaysAuthor(uint256 _payment) public {
        vm.assume(_payment <= 100 ether);
        _deployAndAddPuzzle(address(this));

        // `address(this)` gets first blood.
        curta.solve(1, mockPuzzle.getSolution(address(this)));

        // Warp to Phase 1.
        vm.warp(block.timestamp + 1 days + 1);

        // `address(this)` is the author of puzzle #1.
        uint256 authorBalance = address(this).balance;

        // `0xBEEF` submits during Phase 1.
        uint256 beefSolution = mockPuzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve{ value: _payment }(1, beefSolution);

        // `address(this)` should have received the full payment.
        assertEq(address(this).balance, authorBalance + _payment);
    }

    /// @notice Test whether the ETH amount sent to solve a puzzle during Phase
    /// 2 is paid out to the author.
    /// @dev 0.01 ETH should be transferred to the owner of `curta`, and the
    /// full remaining amount should be transferred to the author.
    /// @param _payment The ETH amount sent via `solve()` during a Phase 2
    /// solve.
    function test_solve_DuringPhase2WithPayment_PaysAuthor(uint256 _payment) public {
        vm.assume(_payment >= PHASE_TWO_MINIMUM_FEE && _payment < 100 ether);
        _deployAndAddPuzzle(address(this));

        // `address(this)` gets first blood.
        curta.solve(1, mockPuzzle.getSolution(address(this)));

        // Warp to Phase 2.
        vm.warp(block.timestamp + PHASE_ONE_LENGTH + 1);

        // `address(this)` is the author of puzzle #1.
        uint256 authorBalance = address(this).balance;
        uint256 protocolBalance = address(curta.owner()).balance;

        // `0xBEEF` submits during Phase 2.
        uint256 beefSolution = mockPuzzle.getSolution(address(0xBEEF));
        vm.prank(address(0xBEEF));
        curta.solve{ value: _payment }(1, beefSolution);

        // The owner of Curta should have received the protocol fee.
        assertEq(address(curta.owner()).balance, protocolBalance + PHASE_TWO_PROTOCOL_FEE);
        // `address(this)` should have received the remaining amount.
        assertEq(address(this).balance, authorBalance + _payment - PHASE_TWO_PROTOCOL_FEE);
    }

    /// @notice Test events emitted and storage variable changes upon solving a
    /// puzzle in phases 0, 1, and 2.
    function test_solve() public {
        uint40 start = uint40(block.timestamp);
        uint40 firstBloodTimestamp;

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
        {
            (
                uint120 colors,
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves
            ) = curta.getPuzzleColorsAndSolves(1);
            assertEq(colors, DEFAULT_FLAG_COLORS);
            assertEq(phase0Solves, 0);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 0);

            (, uint40 addedTimestamp, uint40 firstSolveTimestamp) = curta.getPuzzle(1);
            assertEq(addedTimestamp, start);
            assertEq(firstSolveTimestamp, 0);

            assertTrue(!curta.hasSolvedPuzzle(address(this), 1));

            // `address(this)` owns 1 Authorship Token (the one used to add the
            // puzzle).
            assertEq(authorshipToken.balanceOf(address(this)), 1);

            // `address(this)` owns 0 Flag NFTs.
            assertEq(curta.balanceOf(address(this)), 0);
        }

        // `address(this)` gets first blood.
        uint256 solution = puzzle.getSolution(address(this));
        vm.expectEmit(true, true, true, true);
        emit SolvePuzzle({ id: 1, solver: address(this), solution: solution, phase: 0 });
        curta.solve(1, solution);

        {
            (
                uint120 colors,
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves
            ) = curta.getPuzzleColorsAndSolves(1);
            assertEq(colors, DEFAULT_FLAG_COLORS);
            assertEq(phase0Solves, 1);
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

        // Warp to Phase 1.
        vm.warp(firstBloodTimestamp + 0.5 days);

        // `address(0xBEEF)` has not solved the puzzle yet.
        assertTrue(!curta.hasSolvedPuzzle(address(0xBEEF), 1));
        // `address(0xBEEF)` owns 0 Flag NFTs.
        assertEq(curta.balanceOf(address(0xBEEF)), 0);

        // `0xBEEF` gets a Phase 1 solve.
        uint256 beefSolution = puzzle.getSolution(address(0xBEEF));
        vm.expectEmit(true, true, true, true);
        emit SolvePuzzle({ id: 1, solver: address(0xBEEF), solution: beefSolution, phase: 1 });
        vm.prank(address(0xBEEF));
        curta.solve(1, beefSolution);

        {
            (
                uint120 colors,
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves
            ) = curta.getPuzzleColorsAndSolves(1);
            assertEq(colors, DEFAULT_FLAG_COLORS);
            assertEq(phase0Solves, 1);
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

        // Warp to Phase 2
        vm.warp(firstBloodTimestamp + PHASE_ONE_LENGTH + 1);

        // `address(0xC0FFEE)` has not solved the puzzle yet.
        assertTrue(!curta.hasSolvedPuzzle(address(0xC0FFEE), 1));
        // `address(0xC0FFEE)` owns 0 Flag NFTs.
        assertEq(curta.balanceOf(address(0xC0FFEE)), 0);

        // Cache the balances of the author and protocol owner pre-Phase 2
        // solve.
        uint256 authorBalance = address(this).balance;
        uint256 protocolBalance = address(curta.owner()).balance;

        // `0xC0FFEE` gets a Phase 2 solve.
        uint256 coffeeSolution = puzzle.getSolution(address(0xC0FFEE));
        vm.expectEmit(true, true, true, true);
        emit SolvePuzzle({ id: 1, solver: address(0xC0FFEE), solution: coffeeSolution, phase: 2 });
        vm.prank(address(0xC0FFEE));
        curta.solve{ value: PHASE_TWO_MINIMUM_FEE }(1, coffeeSolution);

        {
            (
                uint120 colors,
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves
            ) = curta.getPuzzleColorsAndSolves(1);
            assertEq(colors, DEFAULT_FLAG_COLORS);
            assertEq(phase0Solves, 1);
            assertEq(phase1Solves, 1);
            assertEq(phase2Solves, 1);
            assertEq(solves, 3);

            assertTrue(curta.hasSolvedPuzzle(address(0xC0FFEE), 1));
        }
        {
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

        // Funds were transferred during `0xC0FFEE`'s Phase 2:
        // The owner of Curta should have received the protocol fee.
        assertEq(curta.owner().balance, protocolBalance + PHASE_TWO_PROTOCOL_FEE);
        // `address(this)` should have received the remaining amount.
        assertEq(
            address(this).balance, authorBalance + PHASE_TWO_MINIMUM_FEE - PHASE_TWO_PROTOCOL_FEE
        );
    }

    // -------------------------------------------------------------------------
    // `setPuzzleColors`
    // -------------------------------------------------------------------------

    /// @notice Test that sender is the author of the puzzle they are trying to
    /// update.
    function test_setPuzzleColors_SetUnauthoredPuzzle_RevertsUnauthorized() public {
        _deployAndAddPuzzle(address(0xBEEF));

        // `address(this)` is not the author of puzzle #1.
        vm.expectRevert(ICurta.Unauthorized.selector);
        curta.setPuzzleColors(1, 1);
    }

    /// @notice Test events emitted and storage variable changes upon setting
    /// new colors for a puzzle.
    function test_setPuzzleColors() public {
        _deployAndAddPuzzle(address(this));

        uint120 newColors = 1;

        // Colors should be 0 by default.
        {
            (uint120 colors,,,,) = curta.getPuzzleColorsAndSolves(1);
            assertEq(colors, DEFAULT_FLAG_COLORS);
        }

        vm.expectEmit(true, true, true, true);
        emit UpdatePuzzleColors(1, newColors);
        curta.setPuzzleColors(1, newColors);

        {
            (uint120 colors,,,,) = curta.getPuzzleColorsAndSolves(1);
            assertEq(colors, newColors);
        }
    }

    // -------------------------------------------------------------------------
    // `setFermat`
    // -------------------------------------------------------------------------

    /// @notice Test that a puzzle requires a solve before it can be set Fermat.
    function test_setFermat_SetUnsolvedPuzzle_Fails() public {
        _deployAndAddPuzzle(address(this));

        // Puzzle #1 has not been solved yet.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleNotSolved.selector, 1));
        curta.setFermat(1);
    }

    /// @notice Test that a puzzle can be set Fermat as soon as there is a
    /// solve, even if there was no prior `fermat` set.
    function test_setFermat_InitialSet_UpdatesStorage() public {
        // Nobody is Fermat yet.
        vm.expectRevert("NOT_MINTED");
        curta.ownerOf(0);

        _deployAndAddPuzzle(address(0xBEEF));

        // Warp forward 1 day and get the first blood as `0xC0FFEE`.
        vm.warp(block.timestamp + 1 days);
        _solveMockPuzzle({ _puzzleId: 1, _as: address(0xC0FFEE) });

        // Now, `setFermat` succeeds because the puzzle has been solved.
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xBEEF), 0);
        curta.setFermat(1);

        assertEq(curta.ownerOf(0), address(0xBEEF));
        assertEq(curta.balanceOf(address(0xBEEF)), 1);
        (uint32 puzzleId, uint40 timeTaken) = curta.fermat();
        assertEq(puzzleId, 1);
        assertEq(timeTaken, 1 days);
    }

    /// @notice Test that anybody can set Fermat.
    /// @param _sender The address to call `setFermat` from.
    function test_setFermat_AsRandomAccount_Succeeds(address _sender) public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        vm.prank(_sender);
        curta.setFermat(1);
    }

    /// @notice Test that a puzzle that is already set Fermat can not be set
    /// Fermat again.
    function test_setFermat_SetSamePuzzleTwice_Fails() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        curta.setFermat(1);

        // Puzzle #1 has already been Fermat.
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleAlreadyFermat.selector, 1));
        curta.setFermat(1);
    }

    /// @notice Test that a puzzle that did not take the longest to go unsolved
    ///  can not be set Fermat.
    function test_setFermat_SetNonFermatPuzzle_Fails() public {
        uint256 start = block.timestamp;

        // Add puzzle as ID #1, and solve it 2 days later.
        _deployAndAddPuzzle(address(this));
        vm.warp(start + 2 days);
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        curta.setFermat(1);

        // Add puzzle as ID #2, and solve it 1 day later. Since puzzle #1 took
        // longer to solve, puzzle #2 should not be eligible for Fermat.
        vm.warp(start);
        _deployAndAddPuzzle(address(this));
        vm.warp(start + 1 days);
        _solveMockPuzzle({ _puzzleId: 2, _as: address(this) });
        vm.expectRevert(abi.encodeWithSelector(ICurta.PuzzleNotFermat.selector, 2));
        curta.setFermat(2);
    }

    /// @notice Test that the contract sets Fermat correctly, even if there was
    /// a previous Fermat set, as long as the previously set Fermat took less
    /// time til first solve.
    function test_setFermat_SetDifferentPuzzlesTwiceInIncreasingOrder_Succeeds() public {
        uint256 start = block.timestamp;

        // Add puzzle as ID #1 from `0xBEEF`, and solve it 2 days later.
        _deployAndAddPuzzle(address(0xBEEF));
        vm.warp(start + 2 days);
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        // Add puzzle as ID #2 from `0xC0FFEE`, and solve it 1 day later.
        vm.warp(start);
        _deployAndAddPuzzle(address(0xC0FFEE));
        vm.warp(start + 1 days);
        _solveMockPuzzle({ _puzzleId: 2, _as: address(this) });

        // Although puzzle #2 took less time to solve, puzzle #1 was not set
        // Fermat, so puzzle #2 should be eligible for Fermat.
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xC0FFEE), 0);
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
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0xC0FFEE), address(0), 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xBEEF), 0);
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
    function test_setFermat_SetAfterTransfer_Succeeds(address _to) public {
        vm.assume(_to != address(0) && _to != address(0xC0FFEE));

        uint256 start = block.timestamp;

        // Add puzzle as ID #1 from `0xBEEF`, and solve it 2 days later.
        _deployAndAddPuzzle(address(0xBEEF));
        vm.warp(start + 2 days);
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        // Add puzzle as ID #2 from `0xC0FFEE`, and solve it 1 day later.
        vm.warp(start);
        _deployAndAddPuzzle(address(0xC0FFEE));
        vm.warp(start + 1 days);
        _solveMockPuzzle({ _puzzleId: 2, _as: address(this) });

        // Although puzzle #2 took less time to solve, puzzle #1 was not set
        // Fermat, so puzzle #2 should be eligible for Fermat.
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xC0FFEE), 0);
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
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(_to), address(0), 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xBEEF), 0);
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
    function test_tokenURI_UnmintedToken_Fails() public {
        vm.expectRevert("NOT_MINTED");
        curta.tokenURI(1);
    }

    /// @notice Test that `tokenURI` does not revert for tokens that exist.
    function test_tokenURI_MintedToken_Succeeds() public {
        if (block.chainid != 1) return;
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        curta.tokenURI((1 << 128) | 0);
    }

    // -------------------------------------------------------------------------
    // Remaining `FlagsERC721` functions
    // -------------------------------------------------------------------------

    /// @notice Test that querying the balance of `address(0)` reverts.
    function test_balanceOf_ZeroAddress_Fails() public {
        vm.expectRevert("ZERO_ADDRESS");
        curta.balanceOf(address(0));
    }

    /// @notice Test that sender must own the token to approve a token.
    function test_approve_SenderIsNotOwner_RevertsUnauthorized() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        vm.prank(address(0xBEEF));
        vm.expectRevert("NOT_AUTHORIZED");
        curta.approve(address(0xBEEF), (1 << 128) | 0);
    }

    /// @notice Test that sender can approve a token if they have been granted
    /// permissions to set approval for all tokens.
    function test_approve_WithApprovalForAllTrue_AllowsTransfer() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        uint256 tokenId = (1 << 128) | 0;

        curta.setApprovalForAll(address(0xBEEF), true);
        vm.prank(address(0xBEEF));
        curta.approve(address(0xBEEF), tokenId);
    }

    /// @notice Test events emitted and state changes when approval is set.
    function test_approve() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        uint256 tokenId = (1 << 128) | 0;

        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), tokenId);
        curta.approve(address(0xBEEF), tokenId);
        assertEq(curta.getApproved(tokenId), address(0xBEEF));
    }

    /// @notice Test events emitted and state changes when approval for all is
    /// set to false.
    function test_setApprovalForAll_False_UpdatesStorage() public {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(address(this), address(0xBEEF), false);
        curta.setApprovalForAll(address(0xBEEF), false);
        assertTrue(!curta.isApprovedForAll(address(this), address(0xBEEF)));
    }

    /// @notice Test events emitted and state changes when approval for all is
    /// set to true.
    function test_setApprovalForAll_True_UpdatesStorage() public {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(address(this), address(0xBEEF), true);
        curta.setApprovalForAll(address(0xBEEF), true);
        assertTrue(curta.isApprovedForAll(address(this), address(0xBEEF)));
    }

    /// @notice Test that the address the token is transferred from must own the
    /// token.
    function test_transferFrom_WrongFrom_Fails() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        vm.expectRevert("WRONG_FROM");
        curta.transferFrom(address(0xBEEF), address(this), (1 << 128) | 0);
    }

    /// @notice Test that tokens can not be transferred to the zero address.
    function test_transferFrom_ToZeroAddress_Fails() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        vm.expectRevert("INVALID_RECIPIENT");
        curta.transferFrom(address(this), address(0), (1 << 128) | 0);
    }

    /// @notice Test that a token can not be transferred if the sender is not
    /// authorized in any way.
    function test_transferFrom_Unauthorized_RevertsUnauthorized() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        vm.expectRevert("NOT_AUTHORIZED");
        vm.prank(address(0xBEEF));
        curta.transferFrom(address(this), address(0xBEEF), (1 << 128) | 0);
    }

    /// @notice Test that sender can transfer a token if they own it.
    function test_transferFrom_SenderIsOwner_AllowsTransfer() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });

        curta.transferFrom(address(this), address(0xBEEF), (1 << 128) | 0);
    }

    /// @notice Test that sender can transfer a token if they have been granted
    /// permissions to transfer all tokens.
    function test_transferFrom_WithApprovalForAllTrue_AllowsTransfer() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        uint256 tokenId = (1 << 128) | 0;

        curta.setApprovalForAll(address(0xBEEF), true);
        vm.prank(address(0xBEEF));
        curta.transferFrom(address(this), address(0xBEEF), tokenId);
    }

    /// @notice Test that sender can transfer a token if they have been granted
    /// permissions to transfer that token.
    function test_transferFrom_WithTokenApproval_AllowsTransfer() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        uint256 tokenId = (1 << 128) | 0;

        curta.approve(address(0xBEEF), tokenId);
        vm.prank(address(0xBEEF));
        curta.transferFrom(address(this), address(0xBEEF), tokenId);
    }

    /// @notice Test events emitted and state changes when a token is
    /// transferred.
    function test_transferFrom() public {
        _deployAndAddPuzzle(address(this));
        _solveMockPuzzle({ _puzzleId: 1, _as: address(this) });
        uint256 solution = mockPuzzle.getSolution(address(this));
        uint56 expectedSolveMetadata =
            uint56(((uint160(address(this)) >> 132) << 28) | (solution & 0xFFFFFFF));
        uint256 tokenId = (1 << 128) | 0;

        // Check state prior to transferring the token.
        {
            (
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves,
                uint32 balance
            ) = curta.getUserBalances(address(this));
            assertEq(phase0Solves, 1);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 1);
            assertEq(balance, 1);

            (address owner, uint40 solveTimestamp, uint56 solveMetadata) =
                curta.getTokenData(tokenId);
            assertEq(owner, address(this));
            assertEq(solveTimestamp, uint40(block.timestamp));
            assertEq(solveMetadata, expectedSolveMetadata);
        }
        {
            (
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves,
                uint32 balance
            ) = curta.getUserBalances(address(0xBEEF));
            assertEq(phase0Solves, 0);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 0);
            assertEq(balance, 0);
        }

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBEEF), tokenId);
        curta.transferFrom(address(this), address(0xBEEF), tokenId);

        // Check state after transferring the token.
        {
            (
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves,
                uint32 balance
            ) = curta.getUserBalances(address(this));
            assertEq(phase0Solves, 1);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 1);
            assertEq(balance, 0);
            assertEq(curta.getApproved(tokenId), address(0));
        }
        {
            (
                uint32 phase0Solves,
                uint32 phase1Solves,
                uint32 phase2Solves,
                uint32 solves,
                uint32 balance
            ) = curta.getUserBalances(address(0xBEEF));
            assertEq(phase0Solves, 0);
            assertEq(phase1Solves, 0);
            assertEq(phase2Solves, 0);
            assertEq(solves, 0);
            assertEq(balance, 1);

            (address owner, uint40 solveTimestamp, uint56 solveMetadata) =
                curta.getTokenData(tokenId);
            assertEq(owner, address(0xBEEF));
            assertEq(solveTimestamp, uint40(block.timestamp));
            assertEq(solveMetadata, expectedSolveMetadata);
        }
    }

    /// @notice Test that `supportsInterface` returns `true` for the correct
    /// interface IDs.
    function test_supportsInterface() public {
        assertEq(curta.supportsInterface(0x01FFC9A7), true); // ERC165
        assertEq(curta.supportsInterface(0x80AC58CD), true); // ERC721
        assertEq(curta.supportsInterface(0x5B5E139F), true); // ERC721Metadata
    }

    // -------------------------------------------------------------------------
    // Miscellaneous
    // -------------------------------------------------------------------------

    /// @dev We add this so `address(this)` can receive funds for testing.
    receive() external payable { }
}
