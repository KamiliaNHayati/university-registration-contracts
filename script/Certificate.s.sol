// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Certificate} from "../src/core/Certificate.sol";

contract CertificateScript is Script {
    Certificate public certificate;

    function setUp() public {}

    function run(
        address students
    ) public returns (Certificate) {
        vm.startBroadcast(); 

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY")); //One of the ways to prevent exposure on GitHub
        //everything after this line, u(foundry) should actually send to the rpc
        
        certificate = new Certificate(
            address(students)
        );

        // and if we done the broadcasting, we're going to do 
        vm.stopBroadcast();
        return certificate;
    }
}
