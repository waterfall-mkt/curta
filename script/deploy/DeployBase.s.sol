// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { FlagRenderer } from "@/contracts/FlagRenderer.sol";
import { LibRLP } from "@/contracts/utils/LibRLP.sol";

/// @notice A script to deploy 1 instance each of `AuthorshipToken`,
/// `FlagRenderer`, and `Curta`. Each of these deploys will be used as each
/// other's initialization values (e.g. the `Curta` deploy will be initialized
/// with with the `AuthorshipToken` and `FlagRenderer` deploys, etc.).
/// @dev The script requires 3 private keys: `DEPLOYER_PRIVATE_KEY`,
/// `AUTHORSHIP_TOKEN_PRIVATE_KEY` and `CURTA_PRIVATE_KEY`, which are all read
/// as environment variables via `vm.envUint`. The account specified by
/// `DEPLOYER_PRIVATE_KEY` will fund the other 2 accounts 0.25 ETH each for gas.
/// Note that if accounts specified by `AUTHORSHIP_TOKEN_PRIVATE_KEY` or
/// `CURTA_PRIVATE_KEY` have a nonzero account nonce or are equal, the script
/// will most likely fail due to incorrect contract address precomputation
/// (the script assumes each account has a nonce of 0).
contract DeployBase is Script {
    // -------------------------------------------------------------------------
    // Environment specific variables
    // -------------------------------------------------------------------------

    /// @notice The address to transfer the Authorship Token's ownership to
    /// immediately after deploy.
    address public immutable authorshipTokenOwner;

    /// @notice The address to transfer the Curta's ownership to immediately
    /// after deploy.
    address public immutable curtaOwner;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 public immutable issueLength;

    /// @notice The number of authors in the initial batch that will receive 1
    /// Authorship Token each.
    uint256 public immutable authorsLength;

    /// @notice The list of authors in the initial batch that will receive 1
    /// Authorship Token each.
    mapping(uint256 => address) public authors;

    // -------------------------------------------------------------------------
    // Deploy addresses
    // -------------------------------------------------------------------------

    /// @notice The instance of `AuthorshipToken` that will be deployed after
    /// the script runs.
    AuthorshipToken public authorshipToken;

    /// @notice The instance of `FlagRenderer` that will be deployed and set in
    /// `curta` as its base `flagRenderer` after the script runs.
    FlagRenderer public flagRenderer;

    /// @notice The instance of `Curta` that will be deployed after the script
    /// runs.
    Curta public curta;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _authorshipTokenOwner The address to transfer the Authorship
    /// Token's ownership to immediately after deploy.
    /// @param _curtaOwner The address to transfer Curta's ownership to
    /// immediately after deploy.
    /// @param _issueLength The number of seconds until an additional token is
    /// made available for minting by the author.
    /// @param _authors The list of authors in the initial batch.
    constructor(
        address _authorshipTokenOwner,
        address _curtaOwner,
        uint256 _issueLength,
        address[] memory _authors
    ) {
        authorshipTokenOwner = _authorshipTokenOwner;
        curtaOwner = _curtaOwner;
        issueLength = _issueLength;

        uint256 length = _authors.length;
        authorsLength = length;
        for (uint256 i; i < length;) {
            authors[i] = _authors[i];
            unchecked {
                ++i;
            }
        }
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

        // Deploy Flag metadata and art renderer contract.
        flagRenderer = new FlagRenderer();
        console.log("Flag Renderer Address: ", address(flagRenderer));

        // Fund each of the other deployer addresses.
        payable(authorshipTokenDeployerAddress).transfer(0.4 ether);
        payable(curtaDeployerAddress).transfer(0.4 ether);

        vm.stopBroadcast();

        // ---------------------------------------------------------------------
        // As `authorshipTokenKey`
        // ---------------------------------------------------------------------

        vm.startBroadcast(authorshipTokenKey);

        // Create an array of the initial authors.
        uint256 length = authorsLength;
        address[] memory initialAuthors = new address[](length);
        for (uint256 i; i < length;) {
            initialAuthors[i] = authors[i];
            unchecked {
                ++i;
            }
        }

        // Deploy the Authorship Token contract.
        authorshipToken = new AuthorshipToken(curtaAddress, issueLength, initialAuthors);
        console.log("Authorship Token Address: ", address(authorshipToken));
        // Transfer ownership to `authorshipTokenOwner`.
        authorshipToken.transferOwnership(authorshipTokenOwner);

        vm.stopBroadcast();

        // ---------------------------------------------------------------------
        // As `curtaKey`
        // ---------------------------------------------------------------------

        vm.startBroadcast(curtaKey);

        // Deploy Curta contract,
        curta = new Curta(authorshipToken, flagRenderer);
        console.log("Curta Address: ", address(curta));
        // Transfer ownership to `curtaOwner`.
        curta.transferOwnership(curtaOwner);

        vm.stopBroadcast();
        console.log("AuthorshipToken Owner: ", authorshipToken.owner());
        console.log("Curta Owner: ", curta.owner());
    }
}
