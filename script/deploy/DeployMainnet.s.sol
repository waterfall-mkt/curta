// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DeployBase } from "./DeployBase.s.sol";

/// @notice A script to deploy the protocol on mainnet.
contract DeployMainnet is DeployBase {
    /// @notice The address to transfer the ownership of the Authorship Token
    /// to.
    address constant AUTHORSHIP_TOKEN_OWNER = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    /// @notice The address to transfer the ownership of Curta to.
    address constant CURTA_OWNER = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 constant ISSUE_LENGTH = 3 days;

    /// @notice The list of authors in the initial batch.
    address[] internal AUTHORS = [
        // fiveoutofnine.eth
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        // fiveoutofnine.eth
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        // fiveoutofnine.eth
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        // fiveoutofnine.eth
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        // fiveoutofnine.eth
        0xA85572Cd96f1643458f17340b6f0D6549Af482F5,
        // shanefan.eth
        0xaFDc1A3EF3992f53C10fC798d242E15E2F0DF51A,
        // Gitswitch
        0x8FC68A56f9682312953a1730Ae62AFD1a99FdC4F,
        // t11s.eth
        0x7eD52863829AB99354F3a0503A622e82AcD5F7d3,
        // nick.eth
        0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5,
        // dom.eth
        0xF296178d553C8Ec21A2fBD2c5dDa8CA9ac905A00,
        // 0age.eth
        0x0734d56DA60852A03e2Aafae8a36FFd8c12B32f1,
        // w1nt3r.eth
        0x1E79b045Dc29eAe9fdc69673c9DCd7C53E5E159D,
        // brocke.eth
        0x230d31EEC85F4063a405B0F95bdE509C0d0A8b5D,
        // smsunarto.eth
        0xea23c259b637f72D80697D4A4D1302df9f64530B,
        // johnpalmer.eth
        0xB0623C91c65621df716aB8aFE5f66656B21A9108,
        // axic.eth
        0x068484F7BD2b7D7C5a698d89e75ddcaf3a92B879,
        // leoalt.eth
        0x12518c3c808ef33E496Fd42033BD312919CD3FE1,
        // Hari
        0xB578405Df1F9D4dFdD46a0BD152D518d4c5Fe0aC,
        // osec.eth
        0xb3Fd340Cb00f7d1b27556E7231a93CA6ffa0Bd57,
        // divergencevault.eth
        0x174787a207BF4eD4D8db0945602e49f42c146474,
        // ret2jazzy.eth
        0xfEe555E9367B83fB0952A945539FAAE54f0560A4,
        // devtooligan.eth
        0xE7aa7AF667016837733F3CA3809bdE04697730eF,
        // waldenyan.eth
        0xd84365dAd6e6dB6fa2d431992acB1e050789bE69,
        // cxkoda.eth
        0x46622E91F95F274f4f76460B38d1F5E00905f767,
        // alexangel.eth
        0x152Ac2bC1821C5C9ecA56D1F35D8b0D8b61187F5,
        // Riley Holterhus
        0xB958d9FA0417E116F446D0A06D0326805Ad73Bd5,
        // wei3rhase
        0xBad58e133138549936D2576ebC33251bE841d3e9,
        // Cygaar
        0x6dacb7352B4eC1e2B979a05E3cF1F126AD641110,
        // Kurt Barry
        0x040dBC0811377DcFA98FFaBBE7F6b2F411986931,
        // foobar
        0xd6Da3f2B9eC0E51BA0c6AEe4080a8179246962ed
    ];

    constructor() DeployBase(AUTHORSHIP_TOKEN_OWNER, CURTA_OWNER, ISSUE_LENGTH, AUTHORS) { }
}
