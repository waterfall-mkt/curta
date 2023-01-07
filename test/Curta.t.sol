// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Curta.sol";

contract CurtaTest is Test {
    Curta internal curta;

    function setUp() public {
        curta = new Curta();
    }
}
