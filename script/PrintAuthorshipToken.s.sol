// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";

contract PrintAuthorshipTokenScriptScript is Script {
    AuthorshipToken internal authorshipToken;

    function run() public {
        address[] memory authors;
        authorshipToken = new AuthorshipToken(address(0xDEAF), 1 days, authors);
        vm.warp(block.timestamp + 10 days);

        for (uint256 i; i < 10; ++i) {
            authorshipToken.ownerMint(address(this));
        }

        console.log(authorshipToken.tokenURI(9));
    }
}
