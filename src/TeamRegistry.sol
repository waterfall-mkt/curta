// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TeamRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when a member is already part of a team.
    /// @param  member The member of the team.
    error AlreadyInTeam(address member);

    /// @notice Emitted when the caller is the team leader.
    /// @param  teamId The ID of the team.
    /// @param  leader The leader of the team.
    error IsTeamLeader(uint32 teamId, address leader);

    /// @notice Emitted when the user does not have a pending invite.
    /// @param  teamId The ID of the team.
    /// @param  member The member of the team.
    error NoPendingInvite(uint32 teamId, address member);

    /// @notice Emitted when the player is not a team member.
    /// @param  teamId The ID of the team.
    /// @param  player The player.
    error NotInTeam(uint32 teamId, address player);

    /// @notice Emitted when the caller is not the team leader.
    /// @param  teamId The ID of the team.
    /// @param  player The member of the team.
    error NotTeamLeader(uint32 teamId, address player);

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

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice Mapping for keeping track of which members are part of teams.
    /// @dev Returns a uint8 that determines status of the team member.
    ///      `0`: Neither in team nor invited
    ///      `1`: Invited to team but not yet accepted
    ///      `2`: Accepted invite and is team member
    ///      `3`: Is team leader
    mapping(uint32 => mapping(address => uint8)) public teamMemberStatus;

    /// @notice Returns boolean if the address is a member of a team.
    mapping(address => bool) public isTeamMember;

    /// @notice Team ID counter. Starts at 1.
    uint16 teamId;

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Create a team with a list of members.
    /// @param  _members The team members to create the team with.
    /// @dev    Reverts if `msg.sender` is already in a team.
    function createTeam(address[] calldata _members) external {
        // team leaders cannot create multiple teams
        if (isTeamMember[msg.sender] == true) revert AlreadyInTeam(msg.sender);
        // increment teamId
        teamId += 1;
        // make `msg.sender` team leader and say they are part of a team
        teamMemberStatus[teamId][msg.sender] = 3;
        isTeamMember[msg.sender] = true;
        // send invites
        for (uint8 i; i < _members.length;) {
            // cannot create team with members of another team
            if (isTeamMember[_members[i]] == true) {
                revert AlreadyInTeam(_members[i]);
            }
            teamMemberStatus[teamId][_members[i]] = 1;
            unchecked {
                i++;
            }
        }

        emit TeamCreated(teamId, msg.sender);
    }

    /// @notice Invite a member to a team.
    /// @param  _teamId The ID of the team.
    /// @param  _member The team member to invite.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or if `_member` is already part of a team.
    function inviteMember(uint32 _teamId, address _member) external {
        if (teamMemberStatus[_teamId][msg.sender] < 3) revert NotTeamLeader(_teamId, msg.sender);
        if (isTeamMember[_member] == true) revert AlreadyInTeam(_member);
        teamMemberStatus[_teamId][_member] = 1;
    }

    /// @notice Invite members to a team.
    /// @param  _teamId The ID of the team.
    /// @param  _members The team members to invite.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or if a member is already part of a team.
    function inviteMembers(uint32 _teamId, address[] calldata _members) external {
        if (teamMemberStatus[_teamId][msg.sender] < 3) revert NotTeamLeader(_teamId, msg.sender);
        for (uint8 i; i < _members.length;) {
            if (isTeamMember[_members[i]] == true) revert AlreadyInTeam(_members[i]);
            teamMemberStatus[_teamId][_members[i]] = 1;
            unchecked {
                i++;
            }
        }
    }

    /// @notice Accept an invite to a team.
    /// @param  _teamId The ID of the team.
    /// @dev    Reverts if `msg.sender` is already in a team or
    ///         has no pending invite.
    function acceptInvite(uint32 _teamId) external {
        if (isTeamMember[msg.sender] == true) revert AlreadyInTeam(msg.sender);
        if (teamMemberStatus[_teamId][msg.sender] != 1) revert NoPendingInvite(_teamId, msg.sender);
        teamMemberStatus[_teamId][msg.sender] == 2;
        isTeamMember[msg.sender] = true;

        emit TeamInviteAccepted(_teamId, msg.sender);
    }

    /// @notice Kick a team member.
    /// @param  _teamId The ID of the team.
    /// @param  _member The team member to kick.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or if `_member` is not in the team.
    function kickMember(uint32 _teamId, address _member) external {
        if (teamMemberStatus[_teamId][msg.sender] < 3) revert NotTeamLeader(_teamId, msg.sender);
        if (teamMemberStatus[_teamId][_member] < 2) revert NotInTeam(_teamId, msg.sender);
        delete teamMemberStatus[_teamId][_member];
        isTeamMember[_member] = false;
    }

    /// @notice Kick multiple team members.
    /// @param  _teamId The ID of the team.
    /// @param  _members The team members to kick.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    /// @dev    Leader can kick self but team will be leaderless.
    function kickMembers(uint32 _teamId, address[] calldata _members) external {
        if (teamMemberStatus[_teamId][msg.sender] < 3) revert NotTeamLeader(_teamId, msg.sender);
        for (uint8 i; i < _members.length;) {
            if (teamMemberStatus[_teamId][_members[i]] < 2) revert NotInTeam(_teamId, msg.sender);
            delete teamMemberStatus[_teamId][_members[i]];
            isTeamMember[_members[i]] = false;
        }
    }

    /// @notice Leave a team.
    /// @param  _teamId The ID of the team.
    /// @dev    Reverts on leader leaving own team or if not a team member.
    function leaveTeam(uint32 _teamId) external {
        if (teamMemberStatus[_teamId][msg.sender] == 3) revert IsTeamLeader(_teamId, msg.sender);
        if (teamMemberStatus[_teamId][msg.sender] < 2) revert NotInTeam(_teamId, msg.sender);
        delete teamMemberStatus[_teamId][msg.sender];
        isTeamMember[msg.sender] = false;
    }

    /// @notice Transfer team leadership to another member.
    /// @param  _teamId The ID of the team.
    /// @param  _newLeader The address of the new leader.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or `_newLeader` is not a team member.
    function transferTeamOwnership(uint32 _teamId, address _newLeader) external {
        if (teamMemberStatus[_teamId][msg.sender] < 3) revert NotTeamLeader(_teamId, msg.sender);
        if (teamMemberStatus[_teamId][_newLeader] != 2) revert NotInTeam(_teamId, _newLeader);
        teamMemberStatus[_teamId][msg.sender] = 2;
        teamMemberStatus[_teamId][_newLeader] = 3;

        emit TeamLeadershipTransferred(_teamId, msg.sender, _newLeader);
    }
}
