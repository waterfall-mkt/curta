// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import "forge-std/Test.sol";

import { AuthorshipToken } from "@/AuthorshipToken.sol";
import { Curta } from "@/Curta.sol";
import { IPuzzle } from "@/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { LibRLP } from "@/utils/LibRLP.sol";

abstract contract DeployBase is Script {
    // Environment specific variables.
    ITokenRenderer private immutable tokenRenderer;
    IPuzzle private immutable puzzle;
    address private immutable owner;

    // Deploy addresses.
    AuthorshipToken public authorshipToken;
    Curta public curta;

    constructor(
        ITokenRenderer _tokenRenderer,
        IPuzzle _puzzle,
        address _owner
    ) {
        tokenRenderer = _tokenRenderer;
        puzzle = _puzzle;
        owner = _owner;
    }

    function run() public virtual {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 curtaKey = vm.envUint("CURTA_PRIVATE_KEY");
        uint256 authorshipTokenKey = vm.envUint("AUTHORSHIP_TOKEN_PRIVATE_KEY");

        address curtaDeployerAddress = vm.addr(curtaKey);
        address authorshipTokenDeployerAddress = vm.addr(authorshipTokenKey);

        // Precomputed contract addresses, based on contract deploy nonces.
        address curtaAddress = LibRLP.computeAddress(curtaDeployerAddress, 0);
        address authorshipTokenAddress = LibRLP.computeAddress(authorshipTokenDeployerAddress, 0);

        vm.startBroadcast(deployerKey);

        // Fund each of the other deployer addresses.
        payable(curtaDeployerAddress).transfer(0.25 ether);
        payable(authorshipTokenDeployerAddress).transfer(0.25 ether);

        vm.stopBroadcast();

        vm.startBroadcast(authorshipTokenKey);

        // Deploy Authorship Token contract.
        authorshipToken = new AuthorshipToken(
            // Curta contract address:
            curtaAddress,
            // Merkle root (TODO: replace with actual merkle root):
            ""
        );
        console.log("Authorship Token Address: ", address(authorshipToken));
        // authorshipToken.transferOwnership(owner);

        vm.stopBroadcast();

        vm.startBroadcast(curtaKey);

        // Deploy Curta contract,
        curta = new Curta(
            tokenRenderer,
            authorshipToken
        );
        console.log("Curta Address: ", address(curta));

        vm.stopBroadcast();
    }
}
