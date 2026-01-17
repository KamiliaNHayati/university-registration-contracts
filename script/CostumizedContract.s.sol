// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol"; // forge-std stands for forge-standard library
import {ForOwners} from "../src/access/CostumizedContract.sol";

contract CostumizedScript is Script {
    ForOwners public costumizedContract;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(); 
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY")); //One of the ways to prevent exposure on GitHub
        //everything after this line, u(foundry) should actually send to the rpc

        address facultyAndMajor = vm.envAddress("FACULTY_ADDRESS");
        //    constructor(address _facultyAndMajor)
        costumizedContract = new ForOwners(facultyAndMajor);

        // and if we done the broadcasting, we're going to do 
        vm.stopBroadcast();
    }
}
