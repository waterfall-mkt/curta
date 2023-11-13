// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployBaseMainnet } from "@/script/deploy/DeployBaseMainnet.s.sol";

/// @notice Tests the Base mainnet deploy script.
contract DeployBaseMainnetTest is Test {
    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The Base mainnet deploy script.
    DeployBaseMainnet internal deployBaseMainnet;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        vm.deal(vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY")), type(uint64).max);

        deployBaseMainnet = new DeployBaseMainnet();
        deployBaseMainnet.run();
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    /// @notice Test that the addresses were set correctly in each contract's
    /// deploy.
    function test_AddressInitializationCorrectness() public {
        assertEq(
            address(deployBaseMainnet.curta().flagRenderer()),
            address(deployBaseMainnet.flagRenderer())
        );
        assertEq(
            address(deployBaseMainnet.curta().authorshipToken()),
            address(deployBaseMainnet.authorshipToken())
        );
        assertEq(deployBaseMainnet.authorshipToken().curta(), address(deployBaseMainnet.curta()));
    }

    /// @notice Test that the Authorship Token's issue length was set correctly.
    function test_authorshipTokenIssueLengthEquality() public {
        assertEq(deployBaseMainnet.authorshipToken().issueLength(), deployBaseMainnet.issueLength());
    }

    /// @notice Test that the Authorship Token's authors were set.
    function test_authorshipTokenAuthorsEquality() public {
        uint256 totalSupply = deployBaseMainnet.authorshipToken().totalSupply();
        assertEq(totalSupply, deployBaseMainnet.authorsLength());

        unchecked {
            for (uint256 i; i < totalSupply; ++i) {
                assertEq(
                    deployBaseMainnet.authorshipToken().ownerOf(i + 1), deployBaseMainnet.authors(i)
                );
            }
        }
    }

    /// @notice Test that an Authorship Token can be minted after deploy.
    function test_authorshipTokenMinting() public {
        AuthorshipToken authorshipToken = deployBaseMainnet.authorshipToken();

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
            deployBaseMainnet.authorshipToken().owner(), deployBaseMainnet.authorshipTokenOwner()
        );
    }

    /// @notice Test that Curta's ownership was transferred correctly.
    function test_curtaOwnerEquality() public {
        assertEq(deployBaseMainnet.curta().owner(), deployBaseMainnet.curtaOwner());
    }
}
