// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployGoerli } from "@/script/deploy/DeployGoerli.s.sol";

/// @notice Tests the Goerli deploy script.
contract DeployGoerliTest is Test {
    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The mainnet deploy script.
    DeployGoerli internal deployGoerli;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        vm.deal(vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY")), type(uint64).max);

        deployGoerli = new DeployGoerli();
        deployGoerli.run();
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    /// @notice Test that the addresses were set correctly in each contract's
    /// deploy.
    function test_AddressInitializationCorrectness() public {
        assertEq(address(deployGoerli.curta().flagRenderer()), address(deployGoerli.flagRenderer()));
        assertEq(
            address(deployGoerli.curta().authorshipToken()), address(deployGoerli.authorshipToken())
        );
        assertEq(deployGoerli.authorshipToken().curta(), address(deployGoerli.curta()));
    }

    /// @notice Test that the Authorship Token's issue length was set correctly.
    function test_authorshipTokenIssueLengthEquality() public {
        assertEq(deployGoerli.authorshipToken().issueLength(), deployGoerli.issueLength());
    }

    /// @notice Test that the Authorship Token's authors were set.
    function test_authorshipTokenAuthorsEquality() public {
        uint256 totalSupply = deployGoerli.authorshipToken().totalSupply();
        assertEq(totalSupply, deployGoerli.authorsLength());

        unchecked {
            for (uint256 i; i < totalSupply; ++i) {
                assertEq(deployGoerli.authorshipToken().ownerOf(i + 1), deployGoerli.authors(i));
            }
        }
    }

    /// @notice Test that an Authorship Token can be minted after deploy.
    function test_authorshipTokenMinting() public {
        AuthorshipToken authorshipToken = deployGoerli.authorshipToken();

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
        assertEq(deployGoerli.authorshipToken().owner(), deployGoerli.authorshipTokenOwner());
    }

    /// @notice Test that Curta's ownership was transferred correctly.
    function test_curtaOwnerEquality() public {
        assertEq(deployGoerli.curta().owner(), deployGoerli.curtaOwner());
    }
}
