// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/AuthorshipToken.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { Curta } from "@/Curta.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { LibRLP } from "@/utils/LibRLP.sol";

contract CurtaTest is Test {
    BaseRenderer internal tokenRenderer;
    AuthorshipToken internal authorshipToken;
    Curta internal curta;

    function setUp() public {
        tokenRenderer = new BaseRenderer();

        address authorshipTokenAddress = LibRLP.computeAddress(address(this), 1);
        address curtaAddress = LibRLP.computeAddress(address(this), 2);

        authorshipToken = new AuthorshipToken(curtaAddress, "");

        curta = new Curta(ITokenRenderer(address(tokenRenderer)), authorshipToken);
    }
}
