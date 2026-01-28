// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol"; // forge-std stands for forge-standard library
import {Students} from "../src/core/Students.sol";
import {FacultyAndMajor} from "../src/core/FacultyAndMajor.sol";

contract StudentsScript is Script {
    Students public students;

    function setUp() public {}

    function run(
        address facultyAndMajor, 
        uint8 minimumMonth, 
        uint8 maximumMonth, 
        uint8 validityEndMonth, 
        uint8 validityEndDay, 
        uint8 validityYearOffset
    ) public returns (Students) {
        vm.startBroadcast(); 

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY")); //One of the ways to prevent exposure on GitHub
        //everything after this line, u(foundry) should actually send to the rpc
        
        // address facultyAndMajor = vm.envAddress("FACULTY_ADDRESS");        
        //     constructor(address _facultyAndMajor) 
        students = new Students(
            address(facultyAndMajor),
            minimumMonth,
            maximumMonth,
            validityEndMonth,
            validityEndDay,
            validityYearOffset
        );

        // and if we done the broadcasting, we're going to do 
        vm.stopBroadcast();
        return students;
    }
}
