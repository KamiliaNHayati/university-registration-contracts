// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {FacultyAndMajor} from "../src/core/FacultyAndMajor.sol";

contract FacultyAndMajorScript is Script {
    FacultyAndMajor public facultyAndMajor;

    function setUp() public {}

    function run(
        string memory universityName,
        uint8 maxLengthFacultyCode,
        uint8 maxLengthMajorCode
    ) public returns(FacultyAndMajor) {
        vm.startBroadcast(); 
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY")); //One of the ways to prevent exposure on GitHub
        //everything after this line, u(foundry) should actually send to the rpc
        
        facultyAndMajor = new FacultyAndMajor(
            universityName,
            maxLengthFacultyCode,
            maxLengthMajorCode
        ); 

        // and if we done the broadcasting, we're going to do 
        vm.stopBroadcast();
        return facultyAndMajor;
    }
}
