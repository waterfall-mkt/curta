// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Curta Puzzles Team Registry
/// @author Sabnock01
contract TeamRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when `msg.sender` is the team leader.
    error IsTeamLeader();

    /// @notice Emitted when `msg.sender` does not have a pending invite to the
    /// team.
    /// @param teamId The ID of the team.
    /// @param member The address of the member.
    error NoPendingInvite(uint256 teamId, address member);

    /// @notice Emitted when `msg.sender` does not have a pending request to the
    /// team.
    /// @param teamId The ID of the team.
    /// @param member The address of the member.
    error NoPendingRequest(uint256 teamId, address member);

    /// @notice Emitted when `msg.sender` is not part of the team.
    /// @param teamId The ID of the team.
    /// @param member The address of the member.
    error NotInTeam(uint256 teamId, address member);

    /// @notice Emitted when `msg.sender` is not the team leader.
    /// @param teamId The ID of the team.
    /// @param member The address of the member.
    error NotTeamLeader(uint256 teamId, address member);

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
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The total number of teams.
    uint256 internal teamId;

    /// @notice Mapping for keeping track of the status of members in teams.
    /// @dev Returns a 3-bit value where the bits represent the following:
    ///     * Bit 0 (LSb): Whether the member approved to join the team.
    ///     * Bit 1 (LSb): Whether the member approved to join the team.
    ///     * Bit 2 (LSb): Whether the member is the leader of the team.
    /// The following table shows the possible values:
    ///        | Value | Is leader | Leader approved | Member approved |
    ///        |-------|-----------|-----------------|-----------------|
    ///        | 0b000 |        No |              No |              No |
    ///        | 0b001 |        No |              No |             Yes |
    ///        | 0b010 |        No |             Yes |              No |
    ///        | 0b011 |        No |             Yes |             Yes |
    ///        | 0b111 |       Yes |             Yes |             Yes |
    mapping(uint256 => mapping(address => uint256)) public getTeamMemberStatus;

    /// @notice A mapping of team member addresses to their team ID.
    /// @dev If a member is not part of a team, their team ID will be `0`.
    mapping(address => uint256) public getMemberTeamId;

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Create a team with invitations sent out to a list of members.
    /// @dev The function reverts if `msg.sender` is the leader of another team.
    /// @param _members A list of addresses to invite.
    /// @return newTeamId The ID of the created team.
    function createTeam(address[] calldata _members) external returns (uint256 newTeamId) {
        unchecked {
            newTeamId = ++teamId;
        }

        uint256 currentTeamId = getMemberTeamId[msg.sender];
        // Revert if `msg.sender` is already the leader of a team.
        if (getTeamMemberStatus[currentTeamId][msg.sender] & 4 == 4) {
            revert IsTeamLeader();
        }

        // Mark `msg.sender` as leader of the new team.
        getTeamMemberStatus[newTeamId][msg.sender] = 7;
        // Mark new team as `msg.sender`'s team.
        getMemberTeamId[msg.sender] = newTeamId;

        // Mark all members are invited (2 = `0b010`).
        uint256 length = _members.length;
        for (uint256 i; i < length;) {
            // We mark it via `|=` in case the member has already requested to
            // join the team. By doing `|= 2`, we only change bit 1 (0-indexed
            // LSb).
            getTeamMemberStatus[newTeamId][_members[i]] |= 2;

            // Emit event.
            emit LeaderApproveJoin(newTeamId, _members[i]);

            unchecked {
                ++i;
            }
        }

        // Emit event.
        emit CreateTeam(newTeamId, msg.sender);
    }

    /// @notice Request to join a team.
    /// @param _teamId The ID of the team.
    function requestJoin(uint256 _teamId) external {
        // We mark it via `|=` in case the member has already been invited to
        // join the team. By doing `|= 1`, we only change bit 0.
        getTeamMemberStatus[_teamId][msg.sender] |= 1;

        // Emit event.
        emit MemberApproveJoin(_teamId, msg.sender);
    }

    /// @notice Invite a member to a team.
    /// @dev Reverts if `msg.sender` is not the team's leader.
    /// @param _member The address of the member to invite.
    function inviteMember(address _member) external {
        uint256 currentTeamId = getMemberTeamId[msg.sender];
        // Revert if `msg.sender` is not the leader of the team.
        if (getTeamMemberStatus[currentTeamId][msg.sender] & 4 != 4) {
            revert NotTeamLeader(currentTeamId, msg.sender);
        }

        // We mark it via `|=` in case the member has already requested to join
        // the team. By doing `|= 2`, we only change bit 1 (0-indexed LSb).
        getTeamMemberStatus[currentTeamId][_member] |= 2;

        // Emit event.
        emit LeaderApproveJoin(currentTeamId, _member);
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

    /// @notice Accept request to join a team.
    /// @param _member The team member to accept.
    function acceptRequest(address _member) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        if (getTeamMemberStatus[memberId][_member] != 2) revert NoPendingRequest(memberId, _member);
        getTeamMemberStatus[memberId][_member] = 3;
        getMemberTeamId[_member] = memberId;

        emit AddTeamMember(memberId, _member);
    }

    /// @notice Accept requests for membership.
    /// @param  _members The team members to accept.
    function acceptRequests(address[] calldata _members) external {
        uint256 memberId = getMemberTeamId[msg.sender];
        if (getTeamMemberStatus[memberId][msg.sender] < 4) {
            revert NotTeamLeader(memberId, msg.sender);
        }
        for (uint8 i; i < _members.length;) {
            if (getTeamMemberStatus[memberId][_members[i]] != 2) {
                revert NoPendingRequest(memberId, _members[i]);
            }
            getTeamMemberStatus[memberId][_members[i]] = 3;
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
            revert NotTeamLeader(memberId, msg.sender);
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
