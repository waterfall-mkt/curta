// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title  TeamRegistry
/// @author Sabnock01
/// @notice A registry for Curta Cup teams.
contract TeamRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when the caller is the team leader.
    error IsTeamLeader();

    /// @notice Emitted when the user does not have a pending invite.
    /// @param  teamId The ID of the team.
    /// @param  member The member of the team.
    error NoPendingInvite(uint256 teamId, address member);

    /// @notice Emitted when the player is not a team member.
    /// @param  teamId The ID of the team.
    /// @param  player The player.
    error NotInTeam(uint256 teamId, address player);

    /// @notice Emitted when the caller is not the team leader.
    /// @param  teamId The ID of the team.
    /// @param  player The member of the team.
    error NotTeamLeader(uint256 teamId, address player);

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a new team is created.
    /// @param  teamId The ID of the team.
    /// @param  leader The leader of the team.
    event CreateTeam(uint256 teamId, address leader);

    /// @notice Emitted when a team invite has been accepted.
    /// @param  teamId The ID of the team.
    /// @param  member The member of the team that accepted the invite.
    event AcceptTeamInvite(uint256 teamId, address member);

    /// @notice Emitted when team leadership is transferred.
    /// @param  oldLeader The old leader of the team.
    /// @param  newLeader The new leader of the team.
    event TransferTeamLeadership(uint256 teamId, address oldLeader, address newLeader);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice Mapping for keeping track of which members are part of teams.
    /// @dev Returns a uint8 that determines status of the team member.
    /// | Status | Is leader | Approved to join | Accept to join |
    /// |--------|-----------|------------------|----------------|
    /// | 0b000  |        No |               No |             No |
    /// | 0b001  |        No |               No |            Yes |
    /// | 0b010  |        No |              Yes |             No |
    /// | 0b011  |        No |              Yes |            Yes |
    /// | 0b111  |       Yes |              Yes |            Yes |
    mapping(uint256 => mapping(address => uint256)) public getTeamMemberStatus;

    /// @notice Returns the ID of the member's team.
    mapping(address => uint256) public getMemberTeamId;

    /// @notice Team ID counter. Starts at 1.
    uint256 private teamId;

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Create a team with a list of members.
    /// @param  _members The team members to create the team with.
    /// @dev    Reverts if `msg.sender` is already in a team.
    function createTeam(address[] calldata _members) external {
        // increment teamId
        teamId += 1;
        // team leaders cannot create multiple teams
        if (getTeamMemberStatus[getMemberTeamId[msg.sender]][msg.sender] == 4) {
            revert IsTeamLeader();
        }
        // make `msg.sender` team leader and say they are part of a team
        getTeamMemberStatus[teamId][msg.sender] = 4;
        getMemberTeamId[msg.sender] = teamId;
        // send invites
        for (uint8 i; i < _members.length;) {
            getTeamMemberStatus[teamId][_members[i]] = 1;
            unchecked {
                i++;
            }
        }

        emit CreateTeam(teamId, msg.sender);
    }

    /// @notice Invite a member to a team.
    /// @param  _teamId The ID of the team.
    /// @param  _member The team member to invite.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    function inviteMember(uint32 _teamId, address _member) external {
        if (getTeamMemberStatus[_teamId][msg.sender] < 4) revert NotTeamLeader(_teamId, msg.sender);
        getTeamMemberStatus[_teamId][_member] = 1;
    }

    /// @notice Invite members to a team.
    /// @param  _teamId The ID of the team.
    /// @param  _members The team members to invite.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    function inviteMembers(uint32 _teamId, address[] calldata _members) external {
        if (getTeamMemberStatus[_teamId][msg.sender] < 4) revert NotTeamLeader(_teamId, msg.sender);
        for (uint8 i; i < _members.length;) {
            getTeamMemberStatus[_teamId][_members[i]] = 1;
            unchecked {
                i++;
            }
        }
    }

    /// @notice Accept an invite to a team.
    /// @param  _teamId The ID of the team.
    /// @dev    Reverts if `msg.sender` is a team leader
    ///         or has no pending invite.
    function acceptInvite(uint32 _teamId) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[_teamId][msg.sender] != 1) {
            revert NoPendingInvite(_teamId, msg.sender);
        }
        if (getTeamMemberStatus[memberId][msg.sender] == 4) {
            revert IsTeamLeader();
        }
        delete getTeamMemberStatus[memberId][msg.sender];
        getTeamMemberStatus[_teamId][msg.sender] = 3;
        getMemberTeamId[msg.sender] = _teamId;

        emit AcceptTeamInvite(_teamId, msg.sender);
    }

    /// @notice Kick a team member.
    /// @param  _teamId The ID of the team.
    /// @param  _member The team member to kick.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or if `_member` is not in the team.
    function kickMember(uint32 _teamId, address _member) external {
        if (getTeamMemberStatus[_teamId][msg.sender] < 4) revert NotTeamLeader(_teamId, msg.sender);
        if (getTeamMemberStatus[_teamId][_member] < 3) revert NotInTeam(_teamId, _member);
        delete getTeamMemberStatus[_teamId][_member];
        delete getMemberTeamId[_member];
    }

    /// @notice Kick multiple team members.
    /// @param  _teamId The ID of the team.
    /// @param  _members The team members to kick.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    /// @dev    Leader can kick self but team will be leaderless.
    function kickMembers(uint32 _teamId, address[] calldata _members) external {
        if (getTeamMemberStatus[_teamId][msg.sender] < 4) revert NotTeamLeader(_teamId, msg.sender);
        for (uint8 i; i < _members.length;) {
            if (getTeamMemberStatus[_teamId][_members[i]] < 3) {
                revert NotInTeam(_teamId, _members[i]);
            }
            delete getTeamMemberStatus[_teamId][_members[i]];
            delete getMemberTeamId[_members[i]];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Leave a team.
    /// @dev    Reverts on leader leaving own team or if not a team member.
    function leaveTeam() external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] == 4) revert IsTeamLeader();
        delete getTeamMemberStatus[memberId][msg.sender];
        delete getMemberTeamId[msg.sender];
    }

    /// @notice Transfer team leadership to another member.
    /// @param  _teamId The ID of the team.
    /// @param  _newLeader The address of the new leader.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or `_newLeader` is not a team member.
    function transferLeadership(uint32 _teamId, address _newLeader) external {
        if (getTeamMemberStatus[_teamId][msg.sender] < 4) revert NotTeamLeader(_teamId, msg.sender);
        if (getTeamMemberStatus[_teamId][_newLeader] != 3) revert NotInTeam(_teamId, _newLeader);
        getTeamMemberStatus[_teamId][msg.sender] = 3;
        getTeamMemberStatus[_teamId][_newLeader] = 4;

        emit TransferTeamLeadership(_teamId, msg.sender, _newLeader);
    }
}
