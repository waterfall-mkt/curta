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
    // `acceptRequest` and `batchAcceptRequest`
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // `kickMember` and `batchKickMember`
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // `setApprovalForMember` and `batchSetApprovalForMember`
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // `transferTeam`
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // `transferTeamLeadership`
    // -------------------------------------------------------------------------

    /* // -------------------------------------------------------------------------
    // `inviteMember` and `batchInviteMember`
    // -------------------------------------------------------------------------

    /// @notice Test that inviting members as not the team leader fails.
    function test_inviteMember_NotTeamLeader_Fails() public {
        _createTeam();

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 0, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("sudolabel"));
        tr.inviteMember(makeAddr("plotchy"));
    }

    /// @notice Test events emitted and state updates upon inviting a member.
    function test_inviteMember() public {
        _createTeam();

        // Test that `makeAddr("fiveoutofnine)` has not been invited to team 1
        // yet.
        assertTrue(tr.getTeamMemberStatus(1, makeAddr("fiveoutofnine")) & 2 == 0);

        // Invite a member.
        vm.expectEmit(false, false, false, true);
        emit LeaderApproveJoin(1, makeAddr("fiveoutofnine"));
        vm.prank(makeAddr("chainlight"));
        tr.inviteMember(makeAddr("fiveoutofnine"));

        // Test that `makeAddr("fiveoutofnine)` has been invited to team 1.
        assertTrue(tr.getTeamMemberStatus(1, makeAddr("fiveoutofnine")) & 2 == 2);
    } */

    /* function test_inviteMembers() public {
        _createTeam();

        address[] memory tms = new address[](2);
        tms[0] = makeAddr("plotchy");
        tms[1] = makeAddr("popular");

        // Test that team leader can invite members
        vm.prank(makeAddr("chainlight"));
        tr.inviteMembers(1, tms);

        // Test that team members have been invited
        assertEq(tr.teamMemberStatus(1, makeAddr("plotchy")), 1);
        assertEq(tr.teamMemberStatus(1, makeAddr("popular")), 1);

        // Test that non team leaders cannot invite members
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("sudolabel"));
        tr.inviteMembers(1, tms);
    }

    function test_acceptInvite() public {
        _createTeam();

        // Test that members can accept invites
        vm.expectEmit(false, false, false, true);
        emit AcceptTeamInvite(1, makeAddr("sudolabel"));
        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);

        // Test that members cannot accept invites if they are already in a team
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.AlreadyInTeam.selector, makeAddr("chainlight"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.acceptInvite(1);

        // Test that members cannot accept invites if they don't have one pending
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NoPendingInvite.selector, 1, makeAddr("plotchy"))
        );
        vm.prank(makeAddr("plotchy"));
        tr.acceptInvite(1);

        // Test that members are updated after accepting invites
        assertEq(tr.teamMemberStatus(1, makeAddr("sudolabel")), 2);
        assertTrue(tr.isTeamMember(makeAddr("sudolabel")));
    }

    function test_kickMember() public {
        _createTeam();

        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);

        // Test that team leaders can kick a member
        vm.prank(makeAddr("chainlight"));
        tr.kickMember(1, makeAddr("sudolabel"));

        // Test that member statuses have been updated
        assertEq(tr.teamMemberStatus(1, makeAddr("sudolabel")), 0);
        assertFalse(tr.isTeamMember(makeAddr("sudolabel")));

        // Test that non team leaders cannot kick a member
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("sudolabel"));
        tr.kickMember(1, makeAddr("sudolabel"));

        // Test that team leaders cannot kick a non team member
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("plotchy"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.kickMember(1, makeAddr("plotchy"));
    }

    function test_kickMembers() public {
        _createTeam();

        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);
        vm.prank(makeAddr("igorline"));
        tr.acceptInvite(1);

        address[] memory tms = new address[](2);
        tms[0] = makeAddr("sudolabel");
        tms[1] = makeAddr("igorline");

        // Test that team leaders can kick members
        vm.prank(makeAddr("chainlight"));
        tr.kickMembers(1, tms);

        // Test that team member statuses have been updated
        assertEq(tr.teamMemberStatus(1, makeAddr("sudolabel")), 0);
        assertEq(tr.teamMemberStatus(1, makeAddr("igorline")), 0);
        assertFalse(tr.isTeamMember(makeAddr("sudolabel")));
        assertFalse(tr.isTeamMember(makeAddr("igorline")));

        tms[0] = makeAddr("chainlight");

        // Test that non team leaders cannot kick members
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("sudolabel"));
        tr.kickMembers(1, tms);

        tms[0] = makeAddr("plotchy");

        // Test that team leaders cannot kick non team members
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("plotchy"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.kickMembers(1, tms);
    }

    function test_leaveTeam() public {
        _createTeam();

        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);

        // Test that members can leave teams
        vm.prank(makeAddr("sudolabel"));
        tr.leaveTeam(1);

        // Test that member status has been updated
        assertEq(tr.teamMemberStatus(1, makeAddr("sudolabel")), 0);
        assertFalse(tr.isTeamMember(makeAddr("sudolabel")));

        // Test that team leaders cannot leave team
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.IsTeamLeader.selector, 1, makeAddr("chainlight"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.leaveTeam(1);

        // Test that non team members cannot leave team
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("plotchy"))
        );
        vm.prank(makeAddr("plotchy"));
        tr.leaveTeam(1);
    }

    function test_transferLeadership() public {
        _createTeam();

        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);
        vm.prank(makeAddr("igorline"));
        tr.acceptInvite(1);

        // Test that team leadership can be transferred
        vm.expectEmit(false, false, false, false);
        emit TransferTeamLeadership(1, makeAddr("chainlight"), makeAddr("sudolabel"));
        vm.prank(makeAddr("chainlight"));
        tr.transferLeadership(1, makeAddr("sudolabel"));

        // Test that member statuses have been updated
        assertEq(tr.teamMemberStatus(1, makeAddr("chainlight")), 2);
        assertEq(tr.teamMemberStatus(1, makeAddr("sudolabel")), 3);

        // Test that non leaders cannot transfer leadership
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1, makeAddr("igorline"))
        );
        vm.prank(makeAddr("igorline"));
        tr.transferLeadership(1, makeAddr("chainlight"));

        // Test that leadership cannot be transferred to non team members
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("plotchy"))
        );
        vm.prank(makeAddr("sudolabel"));
        tr.transferLeadership(1, makeAddr("plotchy"));
    } */

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
        members[2] = makeAddr("jinu");
        members[3] = makeAddr("minimooger");
        members[4] = makeAddr("kalzak");

        vm.prank(makeAddr("chainlight"));
        tr.createTeam(members);
    }
}
