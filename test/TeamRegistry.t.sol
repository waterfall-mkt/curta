// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";

import { TeamRegistry } from "@/contracts/TeamRegistry.sol";

/// @notice Unit tests for {TeamRegistry}, organized by functions.
contract TeamRegistyTest is Test {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a team invite has been accepted.
    /// @param  teamId The ID of the team.
    /// @param  member The member of the team that accepted the invite.
    event AddTeamMember(uint256 teamId, address member);

    /// @notice Emitted when a new team is created.
    /// @param teamId The ID of the team.
    /// @param leader The address of the leader of the team.
    event CreateTeam(uint256 teamId, address leader);

    /// @notice Emitted when a leader invites a member or accepts a member's
    /// request to join a team.
    /// @param teamId The ID of the team.
    /// @param member The address of the member.
    event LeaderApproveJoin(uint256 teamId, address member);

    /// @notice Emitted when a member requests to join or accepts an invitation
    /// to join a team.
    /// @param teamId The ID of the team.
    /// @param member The address of the member.
    event MemberApproveJoin(uint256 teamId, address member);

    /// @notice Emitted when team leadership is transferred.
    /// @param oldLeader The address of the old leader of the team.
    /// @param newLeader The address of the new leader of the team.
    event TransferTeamLeadership(uint256 teamId, address oldLeader, address newLeader);

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

        vm.expectRevert(TeamRegistry.IsTeamLeader.selector);
        _createTeam();
    }

    /// @notice Test events emitted and state updates upon creating a team.
    function test_createTeam(address[] calldata _members) public {
        vm.assume(_members.length > 0);

        vm.expectEmit(false, false, false, true);
        emit CreateTeam(1, address(this));
        tr.createTeam(_members);

        // Test that `msg.sender` is team leader (7) and part of team 1.
        assertEq(tr.getTeamMemberStatus(1, address(this)), 7);
        assertEq(tr.getMemberTeamId(address(this)), 1);

        // Test that all addresses in `_members` have been invited.
        uint256 length = _members.length;
        for (uint256 i; i < length;) {
            assertTrue(tr.getTeamMemberStatus(1, _members[i]) & 2 == 2);

            unchecked {
                i++;
            }
        }

        // Test that team leader cannot create a new team while they're a team
        // leader.
        vm.expectRevert(TeamRegistry.IsTeamLeader.selector);
        tr.createTeam(_members);
    }

    // -------------------------------------------------------------------------
    // `requestJoin`
    // -------------------------------------------------------------------------

    /// @notice Test events emitted and state updates upon creating a team.
    function test_requestJoin() public {
        _createTeam();

        vm.expectEmit(false, false, false, true);
        emit MemberApproveJoin(1, address(this));
        tr.requestJoin(1);

        // Test that `msg.sender` has requested to join team 1.
        assertTrue(tr.getTeamMemberStatus(1, address(this)) & 1 == 1);
    }

    /* function test_inviteMember() public {
        _createTeam();

        // Test that team leader can invite a member
        vm.prank(makeAddr("chainlight"));
        tr.inviteMember(1, makeAddr("plotchy"));

        // Test that the team member has been invited
        assertEq(tr.teamMemberStatus(1, makeAddr("plotchy")), 1);

        // Test that non team leaders cannont invite members
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.NotTeamLeader.selector, 1, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("sudolabel"));
        tr.inviteMember(1, makeAddr("popular"));
    }

    function test_inviteMembers() public {
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

    function _createTeam() internal {
        // create an initial team
        address[] memory tms = new address[](5);
        tms[0] = makeAddr("sudolabel");
        tms[1] = makeAddr("igorline");
        tms[2] = makeAddr("jinu");
        tms[3] = makeAddr("minimooger");
        tms[4] = makeAddr("kalzak");

        vm.prank(makeAddr("chainlight"));
        tr.createTeam(tms);
    }
}
