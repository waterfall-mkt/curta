// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { console } from "forge-std/Test.sol";

import { BaseTest } from "./utils/BaseTest.sol";
import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";

/// @notice Unit tests for `AuthorshipToken`, organized by functions.
contract AuthorshipTokenTest is BaseTest {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @dev Copied from EIP-721.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    // -------------------------------------------------------------------------
    // `curtaMint`
    // -------------------------------------------------------------------------

    /// @notice Test that `curtaMint` must be called by `curta`.
    /// @param _sender The address to call `curtaMint` from.
    function test_curtaMint_SenderIsNotCurta_RevertsUnauthorized(address _sender) public {
        vm.assume(_sender != address(authorshipToken.curta()));

        // Try to mint a token to `0xBEEF` as a sender that is not `curta`.
        vm.expectRevert(AuthorshipToken.Unauthorized.selector);
        vm.prank(_sender);
        authorshipToken.curtaMint(address(0xBEEF));
    }

    /// @notice Test that `curtaMint` mints a token to the specified address.
    function test_curtaMint() public {
        // `0xBEEF` should have no tokens before minting.
        assertEq(authorshipToken.balanceOf(address(0xBEEF)), 0);
        assertEq(authorshipToken.totalSupply(), 0);

        // Mint a token to `0xBEEF` as `curta`.
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xBEEF), 1);
        vm.prank(address(authorshipToken.curta()));
        authorshipToken.curtaMint(address(0xBEEF));

        // `0xBEEF` should have 1 token after minting.
        assertEq(authorshipToken.balanceOf(address(0xBEEF)), 1);
        assertEq(authorshipToken.totalSupply(), 1);
        // The ID of the first token minted should be 1.
        assertEq(authorshipToken.ownerOf(1), address(0xBEEF));
    }

    // -------------------------------------------------------------------------
    // `ownerMint`
    // -------------------------------------------------------------------------

    /// @notice Test that `ownerMint` must be called by the owner.
    /// @param _sender The address to call `ownerMint` from.
    function test_ownerMint_SenderIsNotOwner_RevertUnauthorized(address _sender) public {
        vm.assume(_sender != authorshipToken.owner());

        // Warp to a timestamp after at least 1 token has been issued.
        vm.warp(block.timestamp + ISSUE_LENGTH);

        // Try to mint a token to `0xBEEF` as a sender that is not the owner.
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(_sender);
        authorshipToken.ownerMint(address(0xBEEF));
    }

    /// @notice Test that the owner of the contract can mint tokens via
    /// `ownerMint`.
    function test_ownerMint_SenderIsOwner_AllowsMint() public {
        vm.warp(block.timestamp + ISSUE_LENGTH);

        // `0xBEEF` should have no tokens before minting.
        assertEq(authorshipToken.balanceOf(address(0xBEEF)), 0);
        assertEq(authorshipToken.totalSupply(), 0);

        // Mint a token to `0xBEEF` as the owner.
        vm.prank(authorshipToken.owner());
        authorshipToken.ownerMint(address(0xBEEF));

        // `0xBEEF` should have 1 token after minting.
        assertEq(authorshipToken.balanceOf(address(0xBEEF)), 1);
        assertEq(authorshipToken.totalSupply(), 1);
        // The ID of the first token minted should be 1.
        assertEq(authorshipToken.ownerOf(1), address(0xBEEF));
    }

    /// @notice Test that `ownerMint` mints tokens at the correct rate by
    /// warping forward by `_warpLength` 1000 times and testing whether to
    /// expect a revert or minting all possible amounts.
    /// @param _warpLength The length of time (in seconds) to warp forward by.
    function test_ownerMint_FuzzMintTimestamps_IssuesTokensCorrectly(uint256 _warpLength) public {
        vm.assume(_warpLength >= 1000 && _warpLength <= 2 days);

        uint256 deployTimestamp = authorshipToken.deployTimestamp();
        uint256 numMinted;

        vm.startPrank(authorshipToken.owner());

        unchecked {
            for (uint256 i; i < 1000; ++i) {
                vm.warp(deployTimestamp + _warpLength * i);

                uint256 numIssued = (_warpLength * i) / ISSUE_LENGTH;
                uint256 numMintable = numIssued - numMinted;

                if (numMintable > 0) {
                    // Mint all issued tokens that have not been minted.
                    for (uint256 j; j < numMintable; ++j) {
                        vm.expectEmit(true, true, true, true);
                        emit Transfer(address(0), address(0xBEEF), numMinted + j + 1);
                        authorshipToken.ownerMint(address(0xBEEF));
                    }
                    numMinted += numMintable;
                } else {
                    // If none are mintable, expect a revert.
                    vm.expectRevert(AuthorshipToken.NoTokensAvailable.selector);
                    authorshipToken.ownerMint(address(0xBEEF));
                }

                // Since we minted all tokens that were available, the total
                // supply should be equal to the number of tokens issued.
                assertEq(authorshipToken.totalSupply(), numIssued);
                // All tokens were minted to `0xBEEF`.
                assertEq(authorshipToken.balanceOf(address(0xBEEF)), numIssued);
            }
        }

        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // `tokenURI`
    // -------------------------------------------------------------------------

    /// @notice Test that `tokenURI` reverts for nonexistant tokens.
    function test_tokenURI_UnmintedToken_Fails() public {
        vm.expectRevert("NOT_MINTED");
        authorshipToken.tokenURI(1);
    }

    /// @notice Test that `tokenURI` does not revert for tokens that exist.
    /// @dev If the test is not running off of a mainnet fork, this test will
    /// be skipped.
    function test_tokenURI_MintedToken_Succeeds() public {
        if (block.chainid != 1) return;
        vm.prank(address(authorshipToken.curta()));
        authorshipToken.curtaMint(address(this));

        console.log(authorshipToken.tokenURI(1));
    }
}
