// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";
import { Curta } from "@/contracts/Curta.sol";
import { DeployMainnet } from "@/script/deploy/DeployMainnet.s.sol";

/// @notice Tests the mainnet deploy script.
contract DeployMainnetTest is Test {
    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The mainnet deploy script.
    DeployMainnet internal deployMainnet;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        vm.deal(vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY")), type(uint64).max);

        deployMainnet = new DeployMainnet();
        deployMainnet.run();
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    /// @notice Test that the addresses were set correctly in each contract's
    /// deploy.
    function test_AddressInitializationCorrectness() public {
        assertEq(
            address(deployMainnet.curta().baseRenderer()), address(deployMainnet.baseRenderer())
        );
        assertEq(
            address(deployMainnet.curta().authorshipToken()),
            address(deployMainnet.authorshipToken())
        );
        assertEq(deployMainnet.authorshipToken().curta(), address(deployMainnet.curta()));
    }

    /// @notice Test that the Authorship Token's ownership was transferred
    /// correctly.
    function test_authorshipTokenOwnerEquality() public {
        assertEq(deployMainnet.authorshipToken().owner(), deployMainnet.authorshipTokenOwner());
    }

    /// @notice Test that Curta's ownership was transferred correctly.
    function test_curtaOwnerEquality() public {
        assertEq(deployMainnet.curta().owner(), deployMainnet.curtaOwner());
    }
}
