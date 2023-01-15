// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/AuthorshipToken.sol";
import { BaseRenderer } from "@/BaseRenderer.sol";
import { Curta } from "@/Curta.sol";
import { ITokenRenderer } from "@/interfaces/ITokenRenderer.sol";
import { LibRLP } from "@/utils/LibRLP.sol";

/// @notice A script to deploy 1 instance each of `AuthorshipToken`,
/// `BaseRenderer`, and `Curta`. Each of these deploys will be used as each
/// other's initialization values (e.g. the `Curta` deploy will be initialized
/// with with the `AuthorshipToken` and `BaseRenderer` deploys, etc.).
/// @dev The script requires 3 private keys: `DEPLOYER_PRIVATE_KEY`,
/// `AUTHORSHIP_TOKEN_PRIVATE_KEY` and `CURTA_DEPLOYER_PRIVATE_KEY`, which are
/// all read as environment variables via `vm.envUint`. The account specified
/// by `DEPLOYER_PRIVATE_KEY` will fund the other 2 accounts 0.25 ETH each for
/// gas. Note that if accounts specified by `AUTHORSHIP_TOKEN_PRIVATE_KEY or
/// `CURTA_DEPLOYER_PRIVATE_KEY` have a nonzero account nonce or are equal,
/// the script will most likely fail due to incorrect contract address
/// precomputation (the script assumes each account has a nonce of 0).
abstract contract DeployBase is Script {
    // -------------------------------------------------------------------------
    // Environment specific variables
    // -------------------------------------------------------------------------

    /// @notice The merkle root of the addresses in the initial Authorship
    /// Token's mintlist.
    bytes32 private immutable authorshipTokenMerkleRoot;

    /// @notice The address to transfer the Authorship Token's ownership to
    /// immediately after deploy.
    address private immutable owner;

    // -------------------------------------------------------------------------
    // Deploy addresses
    // -------------------------------------------------------------------------

    /// @notice The instance of `AuthorshipToken` that will be deployed after
    /// the script runs.
    AuthorshipToken public authorshipToken;

    /// @notice The instance of `BaseRenderer` that will be deployed and set in
    /// `curta` as its base `baseRenderer` after the script runs.
    BaseRenderer public baseRenderer;

    /// @notice The instance of `Curta` that will be deployed after the script
    /// runs.
    Curta public curta;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _authorshipTokenMerkleRoot The merkle root of the addresses in
    /// the initial Authorship Token's mintlist.
    /// @param _owner The address to transfer the Authorship Token's ownership
    /// to immediately after deploy.
    constructor(bytes32 _authorshipTokenMerkleRoot, address _owner) {
        authorshipTokenMerkleRoot = _authorshipTokenMerkleRoot;
        owner = _owner;
    }

    // -------------------------------------------------------------------------
    // Script `run()`
    // -------------------------------------------------------------------------

    /// @notice See description for {DeployBase}.
    /// @dev See notes for {DeployBase}.
    function run() public virtual {
        // Read private keys from the environment.
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 authorshipTokenKey = vm.envUint("AUTHORSHIP_TOKEN_PRIVATE_KEY");
        uint256 curtaKey = vm.envUint("CURTA_PRIVATE_KEY");

        address authorshipTokenDeployerAddress = vm.addr(authorshipTokenKey);
        address curtaDeployerAddress = vm.addr(curtaKey);

        // Precomputed contract addresses.
        // Note that the address of `authorshipToken` can be computed with
        // `LibRLP.computeAddress(authorshipTokenDeployerAddress, 0)`, but it is
        // not necessary for the script.
        address curtaAddress = LibRLP.computeAddress(curtaDeployerAddress, 0);

        // ---------------------------------------------------------------------
        // As `deployerKey`
        // ---------------------------------------------------------------------

        vm.startBroadcast(deployerKey);

        // Deploy Token Renderer contract.
        baseRenderer = new BaseRenderer();

        // Fund each of the other deployer addresses.
        payable(curtaDeployerAddress).transfer(0.25 ether);
        payable(authorshipTokenDeployerAddress).transfer(0.25 ether);

        vm.stopBroadcast();

        // ---------------------------------------------------------------------
        // As `authorshipTokenKey`
        // ---------------------------------------------------------------------

        vm.startBroadcast(authorshipTokenKey);

        // Deploy Authorship Token contract.
        authorshipToken = new AuthorshipToken(
            curtaAddress,
            authorshipTokenMerkleRoot
        );
        console.log("Authorship Token Address: ", address(authorshipToken));
        authorshipToken.transferOwnership(owner);

        vm.stopBroadcast();

        // ---------------------------------------------------------------------
        // As `curtaKey`
        // ---------------------------------------------------------------------

        vm.startBroadcast(curtaKey);

        // Deploy Curta contract,
        curta = new Curta(
            ITokenRenderer(baseRenderer),
            authorshipToken
        );
        console.log("Curta Address: ", address(curta));

        vm.stopBroadcast();
    }
}
