// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployBaseGoerli is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0xDbAacdcadD7c51a325B771ff75B261a1e7baE11c;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0xDbAacdcadD7c51a325B771ff75B261a1e7baE11c;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 3 days;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = new address[](0);

    constructor() DeployBase(AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }
}
