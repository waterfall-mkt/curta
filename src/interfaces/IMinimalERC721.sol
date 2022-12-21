// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinimalERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}
