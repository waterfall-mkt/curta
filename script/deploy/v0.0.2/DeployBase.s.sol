// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script, console } from "forge-std/Script.sol";
import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { FlagRenderer } from "@/contracts/FlagRenderer.sol";

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
    address curtaDeployer = 0x63F1E3CCA306a9818F6F5c76AD491a9293C57d76;

    // -------------------------------------------------------------------------
    // Deployment addresses
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

    /// @notice Address of the Create2Deployer
    /// @dev This address is different on all chains except Base mainnet
    /// where it is a predeploy.
    address create2Deployer; 

    /// @notice The expected address for the deployed `FlagRenderer`.
    address flagRendererAddress = 0xF1a9000080AdCB839aC55E2996c3e0c9602C2Ae4;

    /// @notice The expected address for the deployed `AuthorshipToken`.
    address authorshipTokenAddress = 0xC0ffe50b579c2695F42049a5351FF3a37794c872;

    /// @notice The expected address for the deployed `Curta`.
    address curtaAddress = 0x0000000041968e6fB76560021ee7D83175ed7eD1;

    constructor(
        address _create2Deployer,
        address _authorshipTokenOwner,
        address _curtaOwner,
        uint256 _issueLength,
        address[] memory _authors
    ) {
        create2Deployer = _create2Deployer;
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

        // Compute and print initcode hashes for each contract
        // _printInitcodeHashes(initialAuthors);

        vm.startBroadcast();

        // Deploy FlagRenderer
        create2Deployer.call(abi.encodeWithSignature(
            "deploy(uint256,bytes32,bytes)",
            0,
            bytes32(uint256(27228880951058027584878031418626584945025905217501640862369820082332481093632)),
            type(FlagRenderer).creationCode
        ));

        // Deploy AuthorshipToken
        create2Deployer.call(abi.encodeWithSignature(
            "deploy(uint256,bytes32,bytes)",
            0,
            bytes32(uint256(6447998015847004963245564656868529952164055284815449929101636674540665831424)),
            abi.encodePacked(
                type(AuthorshipToken).creationCode,
                abi.encode(
                    curtaAddress,
                    issueLength,
                    initialAuthors
                )
            )
        ));

        // Deploy Curta
        curta = new Curta(
            AuthorshipToken(authorshipTokenAddress), 
            FlagRenderer(flagRendererAddress)
        );

        vm.stopBroadcast();

        flagRenderer = FlagRenderer(flagRendererAddress);
        authorshipToken = AuthorshipToken(authorshipTokenAddress);
    }

    function _printInitcodeHashes(address[] memory initialAuthors) internal view {
        console.logBytes32(keccak256(abi.encodePacked(type(FlagRenderer).creationCode)));
        console.logBytes32(
            keccak256(            
                abi.encodePacked(
                    type(AuthorshipToken).creationCode,
                    abi.encode(
                        curtaAddress,
                        issueLength,
                        initialAuthors
                    )
                )
            )
        );
    }
}