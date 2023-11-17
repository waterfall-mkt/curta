// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";

import { TeamRegistry } from "@/contracts/TeamRegistry.sol";

/// @notice Unit tests for {TeamRegistry}, organized by functions.
contract TeamRegistyTest is Test {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a new team is created.
    /// @param _id The ID of the team.
    /// @param _leader The address of the leader of the team.
    event CreateTeam(uint256 indexed _id, address indexed _leader);

    /// @notice Emitted when a leader approves a member to join a team.
    /// @param _id The ID of the team.
    /// @param _member The address of the member.
    /// @param _approved Whether `_member` is approved to join the team.
    event SetApprovalForMember(
        uint256 indexed _id, address indexed _member, bool indexed _approved
    );

    /// @notice Emitted when a member transfers to another team.
    /// @dev Team ID of 0 denotes that the member is not part of a team (i.e.
    /// they are participating individually).
    /// @param _from The team ID of the team the member is transferring from.
    /// @param _to The team ID of the team the member is transferring to.
    /// @param _member The address of the member.
    event TransferTeam(uint256 indexed _from, uint256 indexed _to, address indexed _member);

    /// @notice Emitted when team leadership is transferred.
    /// @param _id The ID of the team.
    /// @param _from The address of the old leader of the team.
    /// @param _to The address of the new leader of the team.
    event TransferTeamLeadership(uint256 indexed _id, address indexed _from, address indexed _to);

    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The team registry contract.
    TeamRegistry public tr;

    // -------------------------------------------------------------------------
    // Set up
    // -------------------------------------------------------------------------

    /// @notice Set up the test contract by deploying an instance of
    /// {TeamRegistry}.
    function setUp() public {
        tr = new TeamRegistry();
    }

    // -------------------------------------------------------------------------
    // `createTeam`
    // -------------------------------------------------------------------------

    /// @notice Test that a team leader can not create a new team.
    function test_createTeam_TeamLeaderCreatesNewTeam_Fails() public {
        _createTeam();

        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.IsTeamLeader.selector, 1));
        _createTeam();
    }

    /// @notice Test events emitted and state updates upon creating a team.
    /// @param _members The member to invite to the team..
    function test_createTeam(address[] calldata _members) public {
        vm.assume(_members.length > 0);

        // Test that `address(this)` is not the leader of the team 1 yet, and
        // that they're not part of any team yet.
        {
            assertFalse(tr.getApproved(1, address(this)));
            (uint248 teamId, bool isTeamLeader) = tr.getTeam(address(this));
            assertEq(teamId, 0);
            assertFalse(isTeamLeader);
        }

        // Test that `_members` have not been invited yet.
        uint256 length = _members.length;
        for (uint256 i; i < length;) {
            assertFalse(tr.getApproved(1, _members[i]));

            unchecked {
                i++;
            }
        }

        // Create team and invite `_members` (and check emitted events).
        for (uint256 i; i < length;) {
            vm.expectEmit(true, true, true, true);
            emit SetApprovalForMember(1, _members[i], true);

            unchecked {
                i++;
            }
        }
        vm.expectEmit(true, true, true, true);
        emit CreateTeam(1, address(this));
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, address(this), true);
        vm.expectEmit(true, true, true, true);
        emit TransferTeam(0, 1, address(this));
        tr.createTeam(_members);

        // Test that `address(this)` is team leader and part of team 1.
        {
            assertTrue(tr.getApproved(1, address(this)));
            (uint248 teamId, bool isTeamLeader) = tr.getTeam(address(this));
            assertEq(teamId, 1);
            assertTrue(isTeamLeader);
        }

        // Test that all addresses in `_members` have been invited.
        for (uint256 i; i < length;) {
            assertTrue(tr.getApproved(1, _members[i]));

            unchecked {
                i++;
            }
        }

        // Test that team leader cannot create a new team while they're a team
        // leader.
        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.IsTeamLeader.selector, 1));
        tr.createTeam(_members);
    }

    // -------------------------------------------------------------------------
    // `removeMember` and `batchRemoveMember`
    // -------------------------------------------------------------------------

    /// @notice Test that removing a member as not the team leader fails.
    function test_removeMember_NotTeamLeader_Fails() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1)
        );
        vm.prank(makeAddr("sudolabel"));
        tr.removeMember(makeAddr("sudolabel"));
    }

    /// @notice Test that batch removing members as not the team leader fails.
    function test_batchRemoveMember_NotTeamLeader_Fails() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        // Check that `makeAddr("sudolabel")` joined team 1, but is not the team
        // leader.
        {
            (uint248 teamId, bool isLeader) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
            assertFalse(isLeader);
        }

        address[] memory members = new address[](1);
        members[0] = makeAddr("sudolabel");
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1)
        );
        vm.prank(makeAddr("sudolabel"));
        tr.batchRemoveMember(members);
    }

    /// @notice Test that removing an address that's not part of the team fails.
    function test_removeMember_NotTeamMember_Fails() public {
        _createTeam();

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("fiveoutofnine"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.removeMember(makeAddr("fiveoutofnine"));
    }

    /// @notice Test that batch removing addresses that are part of the team
    /// fails.
    function test_batchRemoveMember_NotTeamMember_Fails() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        // Create an array where the first address is part of the team, and the
        // second address is not part of the team.
        address[] memory members = new address[](2);
        members[0] = makeAddr("sudolabel");
        members[1] = makeAddr("plotchy");
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("plotchy"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.batchRemoveMember(members);
    }

    /// @notice Test events emitted and state updates upon removing a member
    /// from a team.
    function test_removeMember() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        // Test that `makeAddr("sudolabel")` is part of team 1.
        {
            (uint248 teamId,) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
        }

        // Remove `makeAddr("sudolabel")` from team 1.
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("sudolabel"), false);
        vm.expectEmit(true, true, true, true);
        emit TransferTeam(1, 0, makeAddr("sudolabel"));
        vm.prank(makeAddr("chainlight"));
        tr.removeMember(makeAddr("sudolabel"));

        // Test that `makeAddr("sudolabel")` is no longer approved to join the
        // team, and that they're no longer part of team .
        {
            assertFalse(tr.getApproved(1, makeAddr("sudolabel")));
            (uint248 teamId,) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 0);
        }
    }

    /// @notice Test events emitted and state updates upon batch removing
    /// members from a team.
    function test_batchRemoveMember() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")` and `makeAddr("igorline")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);
        vm.prank(makeAddr("igorline"));
        tr.transferTeam(1);

        // Test that `makeAddr("sudolabel")` is part of team 1.
        {
            (uint248 teamId,) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
        }
        // Test that `makeAddr("igorline")` is part of team 1.
        {
            (uint248 teamId,) = tr.getTeam(makeAddr("igorline"));
            assertEq(teamId, 1);
        }

        address[] memory members = new address[](2);
        members[0] = makeAddr("sudolabel");
        members[1] = makeAddr("igorline");
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("sudolabel"), false);
        vm.expectEmit(true, true, true, true);
        emit TransferTeam(1, 0, makeAddr("sudolabel"));
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("igorline"), false);
        vm.expectEmit(true, true, true, true);
        emit TransferTeam(1, 0, makeAddr("igorline"));
        vm.prank(makeAddr("chainlight"));
        tr.batchRemoveMember(members);

        // Test that `makeAddr("sudolabel")` is no longer approved to join the
        // team, and that they're no longer part of team.
        {
            assertFalse(tr.getApproved(1, makeAddr("sudolabel")));
            (uint248 teamId,) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 0);
        }

        // Test that `makeAddr("igorline")` is no longer approved to join the
        // team, and that they're no longer part of team.
        {
            assertFalse(tr.getApproved(1, makeAddr("igorline")));
            (uint248 teamId,) = tr.getTeam(makeAddr("igorline"));
            assertEq(teamId, 0);
        }
    }

    // -------------------------------------------------------------------------
    // `setApprovalForMember` and `batchSetApprovalForMember`
    // -------------------------------------------------------------------------

    /// @notice Test that setting approval for a member as not the team leader
    /// fails.
    function test_setApprovalForMember_NotTeamLeader_Fails() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1)
        );
        vm.prank(makeAddr("sudolabel"));
        tr.setApprovalForMember(makeAddr("sudolabel"), true);
    }

    /// @notice Test that batch setting approval for members as not the team
    /// leader fails.
    function test_batchSetApprovalForMember_NotTeamLeader_Fails() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        // Check that `makeAddr("sudolabel")` joined team 1, but is not the team
        // leader.
        {
            (uint248 teamId, bool isLeader) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
            assertFalse(isLeader);
        }

        address[] memory members = new address[](1);
        members[0] = makeAddr("sudolabel");
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1)
        );
        vm.prank(makeAddr("sudolabel"));
        tr.batchSetApprovalForMember(members, false);
    }

    /// @notice Test events emitted and state updates upon setting approval true
    /// for a member, and then setting approval false for a member.
    function test_setApprovalForMember() public {
        _createTeam();

        // Test that `makeAddr("fiveoutofnine")` is not approved to join team 1
        // yet.
        assertFalse(tr.getApproved(1, makeAddr("fiveoutofnine")));

        // Approve `makeAddr("fiveoutofnine")` to join team 1.
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("fiveoutofnine"), true);
        vm.prank(makeAddr("chainlight"));
        tr.setApprovalForMember(makeAddr("fiveoutofnine"), true);

        // Test that `makeAddr("fiveoutofnine")` is approved to join team 1.
        assertTrue(tr.getApproved(1, makeAddr("fiveoutofnine")));

        // Disapprove `makeAddr("fiveoutofnine")` to join team 1.
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("fiveoutofnine"), false);
        vm.prank(makeAddr("chainlight"));
        tr.setApprovalForMember(makeAddr("fiveoutofnine"), false);

        // Test that `makeAddr("fiveoutofnine")` is no longer approved to join
        // team 1.
        assertFalse(tr.getApproved(1, makeAddr("fiveoutofnine")));
    }

    /// @notice Test events emitted and state updates upon batch setting
    /// approval true for members, and then setting approval false for the same
    /// members.
    function test_batchSetApprovalForMember() public {
        _createTeam();

        // Test that `makeAddr("fiveoutofnine")` and `makeAddr("plotchy") are
        // both not approved to join team 1 yet.
        assertFalse(tr.getApproved(1, makeAddr("fiveoutofnine")));
        assertFalse(tr.getApproved(1, makeAddr("plotchy")));

        address[] memory members = new address[](2);
        members[0] = makeAddr("fiveoutofnine");
        members[1] = makeAddr("plotchy");
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("fiveoutofnine"), true);
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("plotchy"), true);
        vm.prank(makeAddr("chainlight"));
        tr.batchSetApprovalForMember(members, true);

        // Test that `makeAddr("fiveoutofnine")` and `makeAddr("plotchy")` are
        // both approved to join team 1.
        assertTrue(tr.getApproved(1, makeAddr("fiveoutofnine")));
        assertTrue(tr.getApproved(1, makeAddr("plotchy")));

        // Disapprove `makeAddr("fiveoutofnine")` to join team 1.
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("fiveoutofnine"), false);
        vm.expectEmit(true, true, true, true);
        emit SetApprovalForMember(1, makeAddr("plotchy"), false);
        vm.prank(makeAddr("chainlight"));
        tr.batchSetApprovalForMember(members, false);

        // Test that `makeAddr("fiveoutofnine")` and `makeAddr("plotchy")` are
        // no longer approved to join team 1.
        assertFalse(tr.getApproved(1, makeAddr("fiveoutofnine")));
        assertFalse(tr.getApproved(1, makeAddr("plotchy")));
    }

    // -------------------------------------------------------------------------
    // `transferTeam`
    // -------------------------------------------------------------------------

    /// @notice Test that transferring teams as a team leader fails.
    function test_transferTeam_IsTeamLeader_Fails() public {
        _createTeam();

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.IsTeamLeader.selector, 1)
        );
        vm.prank(makeAddr("chainlight"));
        tr.transferTeam(1);
    }

    /// @notice Test that transferring to a team that an address is not approved
    /// to join fails.
    function test_transferTeam_ApprovalFalse_Fails() public {
        _createTeam();

        vm.expectRevert(TeamRegistry.Unauthorized.selector);
        vm.prank(makeAddr("fiveoutofnine"));
        tr.transferTeam(1);
    }

    /// @notice Test events emitted and state updates upon transferring teams.
    function test_transferTeam() public {
        _createTeam();

        // Test that `makeAddr("sudolabel")` is not part of team 1 yet.
        {
            (uint248 teamId,) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 0);
        }

        // Transfer team 1 to `makeAddr("sudolabel")`.
        vm.expectEmit(true, true, true, true);
        emit TransferTeam(0, 1, makeAddr("sudolabel"));
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        // Test that `makeAddr("sudolabel")` is part of team 1.
        {
            (uint248 teamId,) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
        }
    }

    // -------------------------------------------------------------------------
    // `transferTeamLeadership`
    // -------------------------------------------------------------------------

    /// @notice Test that transferring team leadership as not the team leader
    /// fails.
    function test_transferTeamLeadership_NotTeamLeader_Fails() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1)
        );
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeamLeadership(makeAddr("sudolabel"));
    }

    /// @notice Test that transferring team leadership to an address that's not
    /// part of the team fails.
    function test_transferTeamLeadership_NotTeamMember_Fails() public {
        _createTeam();

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("fiveoutofnine"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.transferTeamLeadership(makeAddr("fiveoutofnine"));
    }

    /// @notice Test events emitted and state updates upon transferring team
    /// leadership.
    function test_transferTeamLeadership() public {
        _createTeam();

        // Join team 1 as `makeAddr("sudolabel")`.
        vm.prank(makeAddr("sudolabel"));
        tr.transferTeam(1);

        // Test that `makeAddr("chainlight")` is the leader of team 1, and
        // `makeAddr("sudolabel")` is not the team leader of team 1 yet.
        {
            (uint248 teamId, bool isTeamLeader) = tr.getTeam(makeAddr("chainlight"));
            assertEq(teamId, 1);
            assertTrue(isTeamLeader);
        }
        {
            (uint248 teamId, bool isTeamLeader) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
            assertFalse(isTeamLeader);
        }

        // Transfer team leadership to `makeAddr("sudolabel")` (and check
        // emitted events).
        vm.expectEmit(true, true, true, true);
        emit TransferTeamLeadership(1, makeAddr("chainlight"), makeAddr("sudolabel"));
        vm.prank(makeAddr("chainlight"));
        tr.transferTeamLeadership(makeAddr("sudolabel"));

        // Test that `makeAddr("chainlight)` is still part of the team (but no
        // longer the leader), and `makeAddr("sudolabel")` is the team leader of
        // team 1.
        {
            (uint248 teamId, bool isTeamLeader) = tr.getTeam(makeAddr("chainlight"));
            assertEq(teamId, 1);
            assertFalse(isTeamLeader);
        }
        {
            (uint248 teamId, bool isTeamLeader) = tr.getTeam(makeAddr("sudolabel"));
            assertEq(teamId, 1);
            assertTrue(isTeamLeader);
        }
    }

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------

    /// @notice Create a team as `makeAddr("chainlight")`, and invite
    /// `makeAddr("sudolabel")`, `makeAddr("igorline")`, `makeAddr("jinu")`,
    /// `makeAddr("minimooger")`, and `makeAddr("kalzak")`.
    function _createTeam() internal {
        address[] memory members = new address[](5);
        members[0] = makeAddr("sudolabel");
        members[1] = makeAddr("igorline");

        vm.prank(makeAddr("chainlight"));
        tr.createTeam(members);
    }
}
