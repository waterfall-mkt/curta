// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title TeamRegistry
/// @author Sabnock01
/// @notice A registry of teams for Curta Puzzles.
contract TeamRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when `msg.sender` is the team leader.
    /// @param _id The ID of the team.
    error IsTeamLeader(uint256 _id);

    /// @notice Emitted when some address is not part of the team.
    /// @param _id The ID of the team.
    /// @param _member The address of the member.
    error NotInTeam(uint256 _id, address _member);

    /// @notice Emitted when `msg.sender` is not the team leader.
    /// @param _id The ID of the team.
    error NotTeamLeader(uint256 _id);

    /// @notice Emitted when `msg.sender` is unauthorized to join a team.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice A struct containing information about an address's team
    /// membership.
    /// @dev If `id` is 0, the user is not part of any team.
    /// @param id The ID of the team they are a part of.
    /// @param isLeader Whether or not they are the leader of the team.
    struct Team {
        uint248 id;
        bool isLeader;
    }

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
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The total number of teams.
    uint256 internal teamId;

    /// @notice Mapping for whether a member is approved to join a team.
    mapping(uint256 => mapping(address => bool)) public getApproved;

    /// @notice Mapping of team member addresses to the team they are a part of.
    mapping(address => Team) public getTeam;

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Batch remove members from a team.
    /// @dev Since an address may only be part of 1 team at a time, the function
    /// automatically retrieves the team ID to remove from and reverts if
    /// `msg.sender` is not the leader.
    /// @param _members A list of addresses to remove from the team.
    function batchRemoveMember(address[] calldata _members) external {
        Team memory team = getTeam[msg.sender];

        // Revert if `msg.sender` is not the leader of the team.
        if (!team.isLeader) revert NotTeamLeader(team.id);

        // Go through the list and remove members.
        uint256 length = _members.length;
        for (uint256 i; i < length;) {
            _removeMemberFromTeam(team.id, _members[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Batch set approvals for members to join a team.
    /// @dev Since an address may only be part of 1 team at a time, the function
    /// automatically retrieves the team ID to set approvals for and reverts if
    /// `msg.sender` is not the leader.
    /// @param _members A list of addresses to set approvals for.
    /// @param _approved Whether or not the members are approved to join the
    /// team.
    function batchSetApprovalForMember(address[] calldata _members, bool _approved) external {
        Team memory team = getTeam[msg.sender];

        // Revert if `msg.sender` is not the leader of the team.
        if (!team.isLeader) revert NotTeamLeader(team.id);

        // Go through the list and set approval.
        uint256 length = _members.length;
        for (uint256 i; i < length;) {
            _setApprovalForMember(team.id, _members[i], _approved);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Create a team with invitations sent out to a list of members.
    /// @dev The function reverts if `msg.sender` is the leader of another team.
    /// @param _members A list of addresses to invite.
    /// @return newTeamId The ID of the created team.
    function createTeam(address[] calldata _members) external returns (uint256 newTeamId) {
        unchecked {
            newTeamId = ++teamId;
        }

        Team memory team = getTeam[msg.sender];
        // Revert if `msg.sender` is already the leader of a team.
        if (team.isLeader) revert IsTeamLeader(team.id);

        // Mark `msg.sender` as approved to join the team.
        getApproved[newTeamId][msg.sender] = true;
        // Mark new team as `msg.sender`'s team and as leader.
        getTeam[msg.sender] = Team({ id: uint248(newTeamId), isLeader: true });

        // Approve all members to join the team.
        uint256 length = _members.length;
        for (uint256 i; i < length;) {
            getApproved[newTeamId][_members[i]] = true;

            // Emit event.
            emit SetApprovalForMember(newTeamId, _members[i], true);

            unchecked {
                ++i;
            }
        }

        // Emit events.
        emit CreateTeam(newTeamId, msg.sender);
        emit SetApprovalForMember(newTeamId, msg.sender, true);
        emit TransferTeam(team.id, newTeamId, msg.sender);
    }

    /// @notice Remove a member from a team.
    /// @dev Since an address may only be part of 1 team at a time, the function
    /// automatically retrieves the team ID to remove from and reverts if
    /// `msg.sender` is not the leader.
    /// @param _member The address of the member to remove from the team.
    function removeMember(address _member) external {
        Team memory team = getTeam[msg.sender];

        // Revert if `msg.sender` is not the leader of the team.
        if (!team.isLeader) revert NotTeamLeader(team.id);

        _removeMemberFromTeam(team.id, _member);
    }

    /// @notice Set approval for a member to join a team.
    /// @dev Since an address may only be part of 1 team at a time, the function
    /// automatically retrieves the team ID to approve for and reverts if
    /// `msg.sender` is not the leader.
    /// @param _member The address of the member to set approval for.
    /// @param _approved Whether or not the member is approved to join the team.
    function setApprovalForMember(address _member, bool _approved) external {
        Team memory team = getTeam[msg.sender];

        // Revert if `msg.sender` is not the leader of the team.
        if (!team.isLeader) revert NotTeamLeader(team.id);

        _setApprovalForMember(team.id, _member, _approved);
    }

    /// @notice Transfer team from `_from` to `_to`.
    /// @dev Reverts if `msg.sender` is the leader of a team or they are not
    /// approved to join team `_to`.
    /// @param _from The ID of the team to transfer from.
    /// @param _to The ID of the team to transfer to.
    function transferTeam(uint256 _from, uint256 _to) external {
        Team memory team = getTeam[msg.sender];

        // Revert if `msg.sender` is the leader of the team.
        if (team.isLeader) revert IsTeamLeader(team.id);

        // Revert if `msg.sender` is not approved to join the team.
        if (!getApproved[_to][msg.sender]) revert Unauthorized();

        // Transfer team.
        getTeam[msg.sender].id = uint248(_to);

        // Emit event.
        emit TransferTeam(_from, _to, msg.sender);
    }

    /// @notice Transfer team leadership to another member.
    /// @dev Since an address may only be part of 1 team at a time, the function
    /// automatically retrieves the team ID to transfer leadership for and
    /// reverts if `msg.sender` is not the leader or if `_member` is not part
    /// of the team.
    /// @param _member The address of the new leader.
    function transferTeamLeadership(address _member) external {
        Team memory team = getTeam[msg.sender];

        // Revert if `msg.sender` is not the leader of the team.
        if (!team.isLeader) revert NotTeamLeader(team.id);

        // Revert if `_newLeader` is not part of the team.
        if (getTeam[_newLeader].id != team.id) revert NotInTeam(team.id, _newLeader);

        // Transfer leadership.
        getTeam[msg.sender].isLeader = false;
        getTeam[_newLeader].isLeader = true;

        // Emit event.
        emit TransferTeamLeadership(team.id, msg.sender, _newLeader);
    }

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------

    /// @notice Removes a member from a team and emits corresponding events.
    /// @param _teamId The ID of the team.
    /// @param _member The address of the member to remove.
    function _removeMemberFromTeam(uint256 _teamId, address _member) internal {
        // Revert if `_member` is not part of the team.
        if (getTeam[_member].id != _teamId) revert NotInTeam(_teamId, _member);

        // Mark removed member as unapproved to join, and remove them from the
        // team.
        getApproved[_teamId][_member] = false;
        getTeam[_member].id = 0;

        // Emit events.
        emit SetApprovalForMember(_teamId, _member, false);
        emit TransferTeam(_teamId, 0, _member);
    }

    /// @notice Sets approval for a member to join a team and emits
    /// corresponding events.
    /// @param _teamId The ID of the team.
    /// @param _member The address of the member to set approval for.
    /// @param _approved Whether or not the member is approved to join the team.
    function _setApprovalForMember(uint256 _teamId, address _member, bool _approved) internal {
        // Set approval.
        getApproved[_teamId][_member] = _approved;

        // Emit event.
        emit SetApprovalForMember(_teamId, _member, _approved);
    }
}
