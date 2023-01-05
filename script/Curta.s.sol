// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import "../src/BaseRenderer.sol";
import "../src/Curta.sol";
import "../src/AuthorshipToken.sol";
import "../src/mock/MockPuzzle.sol";
import { LibRLP } from "../src/utils/LibRLP.sol";
import { ITokenRenderer } from "../src/interfaces/ITokenRenderer.sol";
import { IMinimalERC721 } from "../src/interfaces/IMinimalERC721.sol";

contract CurtaScript is Script {
    function run() public returns (Curta curta) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        uint256 curtaKey = vm.envUint("CURTA_PRIVATE_KEY");

        address curtaDeployerAddress = vm.addr(curtaKey);
        address curtaAddress = LibRLP.computeAddress(curtaDeployerAddress, 0);

        vm.startBroadcast(deployerPrivateKey);

        // The renderer for Curta
        ITokenRenderer tokenRenderer = new BaseRenderer();

        // Give the Curta deployer some ETH.
        payable(curtaDeployerAddress).transfer(0.25 ether);

        // Deploy the authorship token.
        IMinimalERC721 authorshipToken = new AuthorshipToken(curtaAddress,
            bytes32(keccak256(abi.encodePacked(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)))); // TODO: give valid merkle root

        // Deploy the Mock Puzzle
        // TODO: Remove when deploying for production
        MockPuzzle mockPuzzle = new MockPuzzle();

        vm.stopBroadcast();

        

        // Deploy Curta using the Curta deployer.
        vm.startBroadcast(curtaKey);

        console.log("Predicted CURTA Address: ");
        console.log(curtaAddress);

        curta = new Curta(tokenRenderer, authorshipToken);

        vm.stopBroadcast();
    }
} 
