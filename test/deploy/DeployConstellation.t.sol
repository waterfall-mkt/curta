// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployConstellation } from "@/script/deploy/DeployConstellation.s.sol";

/// @notice Tests the Constellation chain deploy script.
contract DeployConstellationTest is Test {
    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The mainnet deploy script.
    DeployConstellation internal deployConstellation;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        vm.deal(vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY")), type(uint64).max);

        deployConstellation = new DeployConstellation();
        deployConstellation.run();
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    /// @notice Test that the addresses were set correctly in each contract's
    /// deploy.
    function test_AddressInitializationCorrectness() public {
        assertEq(
            address(deployConstellation.curta().flagRenderer()),
            address(deployConstellation.flagRenderer())
        );
        assertEq(
            address(deployConstellation.curta().authorshipToken()),
            address(deployConstellation.authorshipToken())
        );
        assertEq(
            deployConstellation.authorshipToken().curta(), address(deployConstellation.curta())
        );
    }

    /// @notice Test that the Authorship Token's issue length was set correctly.
    function test_authorshipTokenIssueLengthEquality() public {
        assertEq(
            deployConstellation.authorshipToken().issueLength(), deployConstellation.issueLength()
        );
    }

    /// @notice Test that the Authorship Token's authors were set.
    function test_authorshipTokenAuthorsEquality() public {
        uint256 totalSupply = deployConstellation.authorshipToken().totalSupply();
        assertEq(totalSupply, deployConstellation.authorsLength());

        unchecked {
            for (uint256 i; i < totalSupply; ++i) {
                assertEq(
                    deployConstellation.authorshipToken().ownerOf(i + 1),
                    deployConstellation.authors(i)
                );
            }
        }
    }

    /// @notice Test that an Authorship Token can be minted after deploy.
    function test_authorshipTokenMinting() public {
        AuthorshipToken authorshipToken = deployConstellation.authorshipToken();

        // Warp 1 `issueLength` period forward in time to ensure the owner can
        // mint 1.
        vm.warp(block.timestamp + authorshipToken.issueLength() + 1);

        // Mint as owner.
        vm.prank(authorshipToken.owner());
        authorshipToken.ownerMint(address(this));
    }

    /// @notice Test that the Authorship Token's ownership was transferred
    /// correctly.
    function test_authorshipTokenOwnerEquality() public {
        assertEq(
            deployConstellation.authorshipToken().owner(),
            deployConstellation.authorshipTokenOwner()
        );
    }

    /// @notice Test that Curta's ownership was transferred correctly.
    function test_curtaOwnerEquality() public {
        assertEq(deployConstellation.curta().owner(), deployConstellation.curtaOwner());
    }
}
