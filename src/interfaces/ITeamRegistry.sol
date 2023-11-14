// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITeamRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error AlreadyInTeam(address player);

    error NotTeamLeader();

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    struct Team {
        address leader;
        TeamMember[] members;
    }

    struct TeamMember {
        address member;
        bool accepted;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event TeamCreated(uint32 teamID, address teamLeader);

    event TeamDeleted(uint32 teamID);

    event TeamLeadershipTransferred(uint32 teamId, address oldLeader, address newLeader);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    function getEventPuzzleIds(uint32 _eventId) external view returns (uint32[] memory);

    function getTeam(uint32 _teamId) external view returns (Team memory);

    function isTeamMember(address _member) external view returns (bool);

    function setEventPuzzles(uint32 _eventId, uint32[] calldata _puzzleIds) external;

    function createTeam(address[] calldata members) external;

    function acceptInvite(uint32 _teamId) external;

    function kickMember(uint32 _teamId, address _member) external;
    
    function leaveTeam(uint32 _teamId) external;
        
    function transferTeamOwnership(uint32 _teamId, address _newLeader) external;

    function deleteTeam(uint32 _teamId) external;
}