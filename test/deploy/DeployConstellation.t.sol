// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployConstellation } from "@/script/deploy/DeployConstellation.s.sol";

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
            address(deployConstellation.curta().baseRenderer()), address(deployConstellation.baseRenderer())
        );
        assertEq(
            address(deployConstellation.curta().authorshipToken()),
            address(deployConstellation.authorshipToken())
        );
        assertEq(deployConstellation.authorshipToken().curta(), address(deployConstellation.curta()));
    }

    /// @notice Test that Authorship Token's merkle root was set correctly.
    function test_authorshipTokenMerkleRootEquality() public {
        assertEq(
            deployConstellation.authorshipToken().merkleRoot(), deployConstellation.authorshipTokenMerkleRoot()
        );
    }

    /// @notice Test that Authorship Token's ownership was transferred correctly.
    function test_authorshipTokenOwnerEquality() public {
        assertEq(deployConstellation.authorshipToken().owner(), deployConstellation.owner());
    }
}
