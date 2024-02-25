// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script, console } from "forge-std/Script.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { FlagRenderer } from "@/contracts/FlagRenderer.sol";
import { TeamRegistry } from "@/contracts/TeamRegistry.sol";

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

    /// @notice Sender address used for the deployment.
    address curtaDeployer = 0x5F3146D3D700245E998660dBCAe97DcD7a554c05;

    // -------------------------------------------------------------------------
    // Deployment addresses
    // -------------------------------------------------------------------------

    /// @notice The instance of `AuthorshipToken` that will be deployed after
    /// the script runs.
    AuthorshipToken public authorshipToken;

    /// @notice The instance of `FlagRenderer` that will be deployed and set in
    /// `curta` as its base `flagRenderer` after the script runs.
    FlagRenderer public flagRenderer;

    /// @notice The instance of `Curta` that will be deployed.
    Curta public curta;

    /// @notice The instance of `TeamRegistry` that will be deployed.
    TeamRegistry public tr;

    /// @notice Address of the create2 factory to use
    address create2Factory; 

    /// @notice The expected address for the deployed `FlagRenderer`.
    address flagRendererAddress = 0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80;

    /// @notice The expected address for the deployed `AuthorshipToken`.
    address authorshipTokenAddress = 0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d;

    /// @notice The expected address for the deployed `Curta`.
    address curtaAddress = 0x00000000D1329c5cd5386091066d49112e590969;

    /// @notice The expected address for the deployed `TeamRegistry`.
    address teamRegistryAddress = 0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d;

    constructor(
        address _create2Factory,
        address _authorshipTokenOwner,
        address _curtaOwner,
        uint256 _issueLength,
        address[] memory _authors
    ) {
        create2Factory = _create2Factory;
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

    function run() public {
        // Set up authors for AuthorshipToken
        uint256 length = authorsLength;
        address[] memory initialAuthors = new address[](length);
        for (uint256 i; i < length;) {
            initialAuthors[i] = authors[i];
            unchecked {
                ++i;
            }
        }

        vm.startBroadcast();

        // Deploy FlagRenderer
        create2Factory.call(abi.encodeWithSignature(
            "safeCreate2(bytes32,bytes)",
            0x5f3146d3d700245e998660dbcae97dcd7a554c05c8292664421e00010df48664,
            type(FlagRenderer).creationCode
        ));

        flagRenderer = FlagRenderer(flagRendererAddress);

        // Deploy AuthorshipToken
        create2Factory.call(abi.encodeWithSignature(
            "safeCreate2(bytes32,bytes)",
            0x5f3146d3d700245e998660dbcae97dcd7a554c05fcab3fcfdfb00000006ca6b7,
            abi.encodePacked(
                type(AuthorshipToken).creationCode,
                abi.encode(
                    curtaAddress,
                    issueLength,
                    initialAuthors
                )
            )
        ));

        authorshipToken = AuthorshipToken(authorshipTokenAddress);

        // Deploy Curta
        curta = new Curta(
            AuthorshipToken(authorshipTokenAddress), 
            FlagRenderer(flagRendererAddress)
        );

        // Deploy TeamRegistry
        create2Factory.call(abi.encodeWithSignature(
            "safeCreate2(bytes32,bytes)",
            0x5f3146d3d700245e998660dbcae97dcd7a554c05a867800e5eeb00000072a13f,
            type(TeamRegistry).creationCode
        ));

        vm.stopBroadcast();
    }
}