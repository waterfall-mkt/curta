// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";

/// @notice A script to print the token URI returned by `AuthorshipToken` for
/// testing purposes.
/// @dev Either comment out `ICurta(curta).hasUsedAuthorshipToken` in
/// `AuthorshipToken` OR replace `curta` with a valid address and run the script
/// with the corresponding RPC URL to fork with.
contract PrintAuthorshipTokenScript is Script {
    /// @notice The instance of `AuthorshipToken` that will be deployed after
    /// the script runs.
    AuthorshipToken internal authorshipToken;

    /// @notice The address of the live deployed `Curta` contract.
    /// @dev This can be a random address if
    /// `ICurta(curta).hasUsedAuthorshipToken` has been commented out.
    address constant CURTA = address(0xDEAD);

    /// @notice Deploys an instance of `AuthorshipToken`, mints tokens #1, ...,
    /// #9, then prints the token URI for 1 of them.
    function run() public {
        address[] memory authors;
        authorshipToken = new AuthorshipToken(CURTA, 1 days, authors);
        vm.warp(block.timestamp + 10 days);

        for (uint256 i; i < 10; ++i) {
            authorshipToken.ownerMint(address(this));
        }

        console.log(authorshipToken.tokenURI(2));
    }
}
