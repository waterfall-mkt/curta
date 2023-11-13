// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployBaseGoerli } from "@/script/deploy/v0.0.2/DeployBaseGoerli.s.sol";

/// @notice Tests the Base Goerli deploy script.
contract DeployBaseGoerliTest is Test {
    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The Base Goerli deploy script.
    DeployBaseGoerli internal deployBaseGoerli;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        vm.deal(vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY")), type(uint64).max);

        deployBaseGoerli = new DeployBaseGoerli();
        deployBaseGoerli.run();
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    /// @notice Test that the addresses were set correctly in each contract's
    /// deploy.
    function test_AddressInitializationCorrectness() public {
        assertEq(
            address(deployBaseGoerli.curta().flagRenderer()),
            address(deployBaseGoerli.flagRenderer())
        );
        assertEq(
            address(deployBaseGoerli.curta().authorshipToken()),
            address(deployBaseGoerli.authorshipToken())
        );
        assertEq(deployBaseGoerli.authorshipToken().curta(), address(deployBaseGoerli.curta()));
    }

    /// @notice Test that the Authorship Token's issue length was set correctly.
    function test_authorshipTokenIssueLengthEquality() public {
        assertEq(deployBaseGoerli.authorshipToken().issueLength(), deployBaseGoerli.issueLength());
    }

    /// @notice Test that the Authorship Token's authors were set.
    function test_authorshipTokenAuthorsEquality() public {
        uint256 totalSupply = deployBaseGoerli.authorshipToken().totalSupply();
        assertEq(totalSupply, deployBaseGoerli.authorsLength());

        unchecked {
            for (uint256 i; i < totalSupply; ++i) {
                assertEq(
                    deployBaseGoerli.authorshipToken().ownerOf(i + 1), deployBaseGoerli.authors(i)
                );
            }
        }
    }

    /// @notice Test that an Authorship Token can be minted after deploy.
    function test_authorshipTokenMinting() public {
        AuthorshipToken authorshipToken = deployBaseGoerli.authorshipToken();

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
            deployBaseGoerli.authorshipToken().owner(), deployBaseGoerli.authorshipTokenOwner()
        );
    }

    /// @notice Test that Curta's ownership was transferred correctly.
    function test_curtaOwnerEquality() public {
        assertEq(deployBaseGoerli.curta().owner(), deployBaseGoerli.curtaOwner());
    }
}
