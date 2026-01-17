// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol"; // forge-std stands for forge-standard library
import {FacultyAndMajor} from "../src/core/FacultyAndMajor.sol";

contract FacultyScript is Script {
    FacultyAndMajor public facultyAndMajor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(); 
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY")); //One of the ways to prevent exposure on GitHub
        //everything after this line, u(foundry) should actually send to the rpc
        
        facultyAndMajor = new FacultyAndMajor(); 

        // and if we done the broadcasting, we're going to do 
        vm.stopBroadcast();
    }
}
