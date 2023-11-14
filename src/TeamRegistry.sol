// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Owned } from "solmate/auth/Owned.sol";

import { ITeamRegistry } from "@/contracts/interfaces/ITeamRegistry.sol";

contract TeamRegistry is ITeamRegistry, Owned(msg.sender) {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    mapping(uint32 => uint32[]) private eventPuzzleIds;

    mapping(uint32 => Team) private teams;

    mapping(address => bool) private teamMembers;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    function getEventPuzzleIds(
        uint32 _eventId
    ) external view override returns (uint32[] memory) {}

    function getTeam(
        uint32 _teamId
    ) external view override returns (Team memory) {}

    function isTeamMember(
        address _member
    ) external view override returns (bool) {
        return teamMembers[_member];
    }

    function setEventPuzzles(
        uint32 _eventId,
        uint32[] calldata _puzzleIds
    ) external onlyOwner {
        eventPuzzleIds[_eventId] = _puzzleIds;
    }

    function createTeam(address[] calldata _members) external {
        // team leaders cannot create multiple teams
        if (teamMembers[msg.sender] == true) revert AlreadyInTeam(msg.sender);
        // generate team ID
        uint32 _teamId = uint32(
            uint256(keccak256(abi.encodePacked(msg.sender)))
        );
        // say that the team creator is part of a team
        teamMembers[msg.sender] = true;
        TeamMember[] memory tms = new TeamMember[](_members.length + 1);
        tms[0] = TeamMember(msg.sender, true);
        for (uint32 i; i < _members.length; ) {
            // cannot create team with members of another team
            if (teamMembers[_members[i]] == true)
                revert AlreadyInTeam(_members[i]);
            tms[i + 1] = TeamMember(_members[i], false);
            unchecked {
                i++;
            }
        }
        Team memory team = Team(msg.sender, tms);
        teams[_teamId] = team;

        emit TeamCreated(_teamId, msg.sender);
    }

    function acceptInvite(uint32 _teamId) external {
        TeamMember[] memory tms = teams[_teamId].members;
        for (uint32 i; i < tms.length; ) {
            if (tms[i].member == msg.sender) {
                tms[i].accepted = true;
                teamMembers[msg.sender] = true;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    function kickMember(uint32 _teamId, address _member) external {
        Team memory team = teams[_teamId];
        if (msg.sender != team.leader) revert NotTeamLeader();
        for (uint32 i; i < team.members.length; ) {
            if (team.members[i].member == _member) {
                team.members[i].accepted = false;
                teamMembers[_member] = false;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    function leaveTeam(uint32 _teamId) external {
        Team memory team = teams[_teamId];
        for (uint32 i; i < team.members.length; ) {
            if (team.members[i].member == msg.sender) {
                team.members[i].accepted = false;
                teamMembers[msg.sender] = false;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    function transferTeamOwnership(
        uint32 _teamId,
        address _newLeader
    ) external {
        Team memory team = teams[_teamId];
        if (msg.sender != team.leader) revert NotTeamLeader();
        // cannot become leader if not already member
        for (uint32 i; i < team.members.length; ) {
            if (team.members[i].member == _newLeader) {
                team.leader = _newLeader;
                break;
            }
        }

        emit TeamLeadershipTransferred(_teamId, team.leader, _newLeader);
    }

    function deleteTeam(uint32 _teamId) external {
        Team memory team = teams[_teamId];
        if (team.leader != msg.sender) revert NotTeamLeader();
        delete teams[_teamId];
        for (uint32 i; i < team.members.length; ) {
            teamMembers[team.members[i].member] = false;
            unchecked {
                i++;
            }
        }

        emit TeamDeleted(_teamId);
    }
}