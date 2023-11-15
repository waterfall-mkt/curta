// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";

import { TeamRegistry } from "@/contracts/TeamRegistry.sol";

contract TeamRegistyTest is Test {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a new team is created.
    /// @param  teamId The ID of the team.
    /// @param  leader The leader of the team.
    event TeamCreated(uint32 teamId, address leader);

    /// @notice Emitted when a team invite has been accepted.
    /// @param  teamId The ID of the team.
    /// @param  member The member of the team that accepted the invite.
    event TeamInviteAccepted(uint32 teamId, address member);

    /// @notice Emitted when team leadership is transferred.
    /// @param  oldLeader The old leader of the team.
    /// @param  newLeader The new leader of the team.
    event TeamLeadershipTransferred(uint32 teamId, address oldLeader, address newLeader);

    TeamRegistry public tr;

    function setUp() public {
        tr = new TeamRegistry();
    }

    function test_createTeam(address[] calldata members) public {
        vm.assume(members.length > 0);

        vm.expectEmit(false, false, false, true);
        emit TeamCreated(1, address(this));
        tr.createTeam(members);

        // Test that `msg.sender` is team leader and part of a team
        assertEq(tr.teamMemberStatus(1, address(this)), 3);
        assertTrue(tr.isTeamMember(address(this)));

        // Test that all `members` have been invited
        for (uint8 i; i < members.length;) {
            assertEq(tr.teamMemberStatus(1, members[i]), 1);
            unchecked {
                i++;
            }
        }

        // Test that team leader cannot create multiple teams
        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.AlreadyInTeam.selector, address(this)));
        tr.createTeam(members);

        // Test that members of another team cannot be invited by
        // pranking one of the invitees and trying to add this address
        // which is already part of team 1.
        address[] memory tms = new address[](1);
        tms[0] = address(this);

        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.AlreadyInTeam.selector, address(this)));
        vm.prank(members[0]);
        tr.createTeam(tms);
    }

    function test_inviteMember() public {
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

        // Test that team members cannot be invited
        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);

        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.AlreadyInTeam.selector, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.inviteMember(1, makeAddr("sudolabel"));
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

        // Test that team members cannot be invited
        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);

        tms[0] = makeAddr("sudolabel");
        vm.expectRevert(
            abi.encodeWithSelector(TeamRegistry.AlreadyInTeam.selector, makeAddr("sudolabel"))
        );
        vm.prank(makeAddr("chainlight"));
        tr.inviteMembers(1, tms);
    }

    function test_acceptInvite() public {
        _createTeam();

        // Test that members can accept invites
        vm.expectEmit(false, false, false, true);
        emit TeamInviteAccepted(1, makeAddr("sudolabel"));
        vm.prank(makeAddr("sudolabel"));
        tr.acceptInvite(1);

        // Test that members cannot accept invites if they are already in a team
        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.AlreadyInTeam.selector, makeAddr("chainlight")));
        vm.prank(makeAddr("chainlight"));
        tr.acceptInvite(1);

        // Test that members cannot accept invites if they don't have one pending
        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.NoPendingInvite.selector, 1, makeAddr("plotchy")));
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
        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.IsTeamLeader.selector, 1, makeAddr("chainlight")));
        vm.prank(makeAddr("chainlight"));
        tr.leaveTeam(1);

        // Test that non team members cannot leave team
        vm.expectRevert(abi.encodeWithSelector(TeamRegistry.NotInTeam.selector, 1, makeAddr("plotchy")));
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
        emit TeamLeadershipTransferred(1, makeAddr("chainlight"), makeAddr("sudolabel"));
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
    }

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
