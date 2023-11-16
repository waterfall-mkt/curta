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

    /// @notice Emitted when the user does not have a pending request.
    /// @param  teamId The ID of the team.
    /// @param  member The member of the team.
    error NoPendingRequest(uint256 teamId, address member);

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
    event AddTeamMember(uint256 teamId, address member);

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
    /// @return The ID of the created team.
    /// @dev    Reverts if `msg.sender` is a team leader.
    function createTeam(address[] calldata _members) external returns (uint256) {
        // increment teamId
        teamId += 1;
        // team leaders cannot create multiple teams
        if (getTeamMemberStatus[getMemberTeamId[msg.sender]][msg.sender] == 4) {
            revert IsTeamLeader();
        }
        // make `msg.sender` team leader and assign their team
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

        return teamId;
    }

    /// @notice Request membership to a team.
    /// @param  _teamId The ID of the team.
    function requestMembership(uint256 _teamId) external {
        if (getTeamMemberStatus[getMemberTeamId[msg.sender]][msg.sender] == 4) {
            revert IsTeamLeader();
        }
        getTeamMemberStatus[_teamId][msg.sender] = 2;
    }

    /// @notice Invite a member to a team.
    /// @param  _member The team member to invite.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    function inviteMember(address _member) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        getTeamMemberStatus[memberId][_member] = 1;
    }

    /// @notice Invite members to a team.
    /// @param  _members The team members to invite.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    function inviteMembers(address[] calldata _members) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        for (uint8 i; i < _members.length;) {
            getTeamMemberStatus[memberId][_members[i]] = 1;
            unchecked {
                i++;
            }
        }
    }

    /// @notice Accept request for membership.
    /// @param  _member The team member to accept.
    function acceptRequest(address _member) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        if (getTeamMemberStatus[memberId][_member] != 2) revert NoPendingRequest(memberId, _member);
        getTeamMemberStatus[_member][memberId] = 3;
        getMemberTeamId[_member] = memberId;

        emit AddTeamMember(memberId, _member);
    }

    /// @notice Accept requests for membership.
    /// @param  _members The team members to accept.
    function acceptRequests(address[] _members) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        for (uint8 i; i < _members.length;) {
            if (getTeamMemberStatus[memberId][_members[i]] != 2) {
                revert NoPendingRequest(memberId, _members[i]);
            }
            getTeamMemberStatus[_members[i]][memberId] = 3;
            getMemberTeamId[_members[i]] = memberId;

            emit AddTeamMember(memberId, _members[i]);
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

        emit AddTeamMember(_teamId, msg.sender);
    }

    /// @notice Kick a team member.
    /// @param  _member The team member to kick.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or if `_member` is not in the team.
    function kickMember(address _member) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        // don't want to delete teamId's of non-members
        if (getTeamMemberStatus[memberId][_member] < 3) revert NotInTeam(memberId, _member);
        delete getTeamMemberStatus[memberId][_member];
        delete getMemberTeamId[_member];
    }

    /// @notice Kick multiple team members.
    /// @param  _members The team members to kick.
    /// @dev    Reverts if `msg.sender` is not the current leader.
    /// @dev    Leader can kick self but team will be leaderless.
    function kickMembers(address[] calldata _members) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberid, msg.sender);
        }
        for (uint8 i; i < _members.length;) {
            // don't want to delete teamId's of non-members
            if (getTeamMemberStatus[memberId][_members[i]] < 3) {
                revert NotInTeam(memberId, _members[i]);
            }
            delete getTeamMemberStatus[memberId][_members[i]];
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
    /// @param  _newLeader The address of the new leader.
    /// @dev    Reverts if `msg.sender` is not the current leader
    ///         or `_newLeader` is not a team member.
    function transferLeadership(address _newLeader) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        if (getTeamMemberStatus[memberId][_newLeader] != 3) revert NotInTeam(memberId, _newLeader);
        getTeamMemberStatus[memberId][msg.sender] = 3;
        getTeamMemberStatus[memberId][_newLeader] = 4;

        emit TransferTeamLeadership(memberId, msg.sender, _newLeader);
    }
}
