// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {Email} from "../../src/libraries/Email.sol";

contract EmailTest is Test {
    function testToLowercase() public pure {
        assertEq(Email.toLowercase("HELLO"), "hello");
    }
    
    function testConvertSpacesToDots() public pure {
        assertEq(Email.convertSpacesToDots("John Doe"), "john.doe");
    }
    
    // Test truncation (3+ spaces)
    function testConvertSpacesToDots_Truncation() public pure {
        assertEq(Email.convertSpacesToDots("John Middle Last Extra"), "john.middle.last");
    }
}