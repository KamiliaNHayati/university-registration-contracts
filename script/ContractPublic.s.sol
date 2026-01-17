// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol"; // forge-std stands for forge-standard library
import {ContractPublic} from "../src/access/ContractPublic.sol";

contract ContractPublicScript is Script {
    ContractPublic public contractPublic;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(); 
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY")); //One of the ways to prevent exposure on GitHub
        //everything after this line, u(foundry) should actually send to the rpc
        
        address students = vm.envAddress("STUDENT_ADDRESS");
        address myContract = vm.envAddress("COSTUMIZED_ADDRESS");
        //  constructor(address _students, address _myContract)
        contractPublic = new ContractPublic(students, myContract);

        // and if we done the broadcasting, we're going to do 
        vm.stopBroadcast();
    }
}