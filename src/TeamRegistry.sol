// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Owned } from "solmate/auth/Owned.sol";

import { ITeamRegistry } from "@/contracts/interfaces/ITeamRegistry.sol";

contract TeamRegistry is ITeamRegistry, Owned(msg.sender) {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    mapping(uint32 => uint32[]) public getEventPuzzleIds;

    /// @notice Mapping for keeping track of which members are part of teams.abi
    /// @dev Returns a uint8 that determines status of the team member.abi
    ///      `0`: Neither in team nor invited
    ///      `1`: Invited to team but not yet accepted
    ///      `2`: Accepted invite and is team member
    ///      `3`: Is team leader
    mapping(uint32 => mapping(address => uint8)) public teamMembers;

    // modify to bitmap
    mapping(address => bool) public isTeamMember;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    function setEventPuzzles(
        uint32 _eventId,
        uint32[] calldata _puzzleIds
    ) external onlyOwner {
        getEventPuzzleIds[_eventId] = _puzzleIds;
    }

    function createTeam(address[] calldata _members) external {
        // team leaders cannot create multiple teams
        if (isTeamMember[msg.sender] == true) revert AlreadyInTeam(msg.sender);
        // generate team ID
        uint32 teamId = uint32(
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))
        );
        // make them team leader and say they are part of a team
        teamMembers[teamId][msg.sender] = 3;
        isTeamMember[msg.sender] = true;
        // add members including leader
        for (uint32 i; i < _members.length; ) {
            // cannot create team with members of another team
            if (isTeamMember[_members[i]] == true)
                revert AlreadyInTeam(_members[i]);
            teamMembers[teamId][_members[i]] = 1;    // mark member as invited0
            unchecked {
                i++;
            }
        }

        emit TeamCreated(_teamId, msg.sender);
    }

    function acceptInvite(uint32 _teamId) external {
        if(teamMembers[_teamId][msg.sender] != 1) revert NotInvited();
        teamMembers[_teamId][msg.sender] == 2;
        isTeamMember[msg.sender] = true;
    }

    function kickMember(uint32 _teamId, address _member) external {
        if (teamMembers[_teamId][msg.sender] != 3) revert NotTeamLeader();
        delete teamMembers[_teamId][_member];
        isTeamMember[_member] = false;
    }

    function leaveTeam(uint32 _teamId) external {
        delete teamMembers[_teamId][msg.sender];
        isTeamMember[msg.sender] = false;
    }

    function transferTeamOwnership(
        uint32 _teamId,
        address _newLeader
    ) external {
        if (teamMembers[_teamId][msg.sender] != 3) revert NotTeamLeader();
        teamMembers[_teamId][msg.sender] = 2;
        teamMembers[_teamId][_newLeader] = 3;

        emit TeamLeadershipTransferred(_teamId, msg.sender, _newLeader);
    }
}