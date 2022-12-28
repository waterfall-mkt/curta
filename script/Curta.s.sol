// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import "../src/BaseRenderer.sol";
import "../src/Curta.sol";
import "../src/AuthorshipToken.sol";
import { LibRLP } from "../src/utils/LibRLP.sol";
import { ITokenRenderer } from "../src/interfaces/ITokenRenderer.sol";
import { IMinimalERC721 } from "../src/interfaces/IMinimalERC721.sol";

contract CurtaScript is Script {
    function run() public returns (Curta curta) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        uint256 curtaKey = vm.envUint("CURTA_PRIVATE_KEY");
        uint256 authorshipTokenKey = vm.envUint("AUTHORSHIP_TOKEN_PRIVATE_KEY");

        address curtaDeployerAddress = vm.addr(curtaKey);
        address authorshipTokenDeployerAddress = vm.addr(authorshipTokenKey);

        address curtaAddress = LibRLP.computeAddress(curtaDeployerAddress, 0);
        address authorshipTokenAddress = LibRLP.computeAddress(authorshipTokenDeployerAddress, 0);

        // Fund the two deployers with some ETH.
        vm.startBroadcast(deployerPrivateKey);

        // The renderer for Curta
        ITokenRenderer tokenRenderer = new BaseRenderer();

        payable(curtaDeployerAddress).transfer(0.25 ether);
        payable(authorshipTokenDeployerAddress).transfer(0.25 ether);

        vm.stopBroadcast();

        // Deploy AuthorshipToken.
        vm.startBroadcast(authorshipTokenKey);

        IMinimalERC721 authorshipToken = new AuthorshipToken(curtaAddress, bytes32(uint256(0x01))); // TODO: give valid merkle root

        vm.stopBroadcast();

        // Deploy Curta.
        vm.startBroadcast(curtaKey);

        console.log("Predicted CURTA Address: ");
        console.log(curtaAddress);

        curta = new Curta(tokenRenderer, authorshipToken);

        vm.stopBroadcast();
    }
} 
