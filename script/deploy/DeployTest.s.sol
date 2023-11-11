// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script, console } from "forge-std/Script.sol";
import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { FlagRenderer } from "@/contracts/FlagRenderer.sol";

contract DeployTest is Script {
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

    /// @notice Address of the create2 deployer used for deploying
    /// the `FlagRenderer` and `AuthorshipToken` contracts.
    /// @dev https://github.com/pcaversaccio/create2deployer
    address create2Deployer = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;

    /// @notice The expected address for the deployed `FlagRenderer`.
    address flagRendererAddress = 0xF1a900000007Ebb953C4E07f7b0BB7499948D633;

    /// @notice The expected address for the deployed `AuthorshipToken`.
    address authorshipTokenAddress = 0xC0ffeb4D2CA645c29D2E91142477b6AD1928de48;

    /// @notice The expected address for the deployed `Curta`.
    address curtaAddress = 0x0000000041968e6fB76560021ee7D83175ed7eD1;

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

        // // Deploy FlagRenderer
        // create2Deployer.call(abi.encodeWithSignature(
        //     "deploy(uint256,bytes32,bytes)",
        //     0,
        //     bytes32(uint256(90090497120548904119639054063165623713871733104106274266802067322216341911859)),
        //     type(FlagRenderer).creationCode
        // ));

        // // Deploy AuthorshipToken
        // create2Deployer.call(abi.encodeWithSignature(
        //     "deploy(uint256,bytes32,bytes)",
        //     0,
        //     bytes32(uint256(75279863212487021771225337954633704189071165355316145725232311808438629536780)),
        //     abi.encodePacked(
        //         type(AuthorshipToken).creationCode,
        //         abi.encode(
        //             curtaAddress,
        //             issueLength,
        //             initialAuthors
        //         )
        //     )
        // ));

        // Deploy Curta
        Curta curta = new Curta(
            AuthorshipToken(authorshipTokenAddress), 
            FlagRenderer(flagRendererAddress)
        );
        Curta curta2 = new Curta(
            AuthorshipToken(authorshipTokenAddress), 
            FlagRenderer(flagRendererAddress)
        );
        Curta curta3 = new Curta(
            AuthorshipToken(authorshipTokenAddress), 
            FlagRenderer(flagRendererAddress)
        );


        vm.stopBroadcast();
    }

    function _printInitcodeHashes(address[] memory initialAuthors) internal view {
        console.logBytes32(
            keccak256(
                abi.encodePacked(
                    type(FlagRenderer).creationCode,
                    abi.encode(
                        authorshipTokenAddress,
                        curtaAddress
                    )
                )
            )
        );
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