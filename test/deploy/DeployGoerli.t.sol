// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployGoerli } from "@/script/deploy/DeployGoerli.s.sol";

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
        assertEq(
            address(deployGoerli.curta().baseRenderer()), address(deployGoerli.baseRenderer())
        );
        assertEq(
            address(deployGoerli.curta().authorshipToken()),
            address(deployGoerli.authorshipToken())
        );
        assertEq(deployGoerli.authorshipToken().curta(), address(deployGoerli.curta()));
    }

    /// @notice Test that Authorship Token's merkle root was set correctly.
    function test_authorshipTokenMerkleRootEquality() public {
        assertEq(
            deployGoerli.authorshipToken().merkleRoot(), deployGoerli.authorshipTokenMerkleRoot()
        );
    }

    /// @notice Test that Authorship Token's ownership was transferred correctly.
    function test_authorshipTokenOwnerEquality() public {
        assertEq(deployGoerli.authorshipToken().owner(), deployGoerli.owner());
    }
}
