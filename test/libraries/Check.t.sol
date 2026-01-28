// test/libraries/Check.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Check} from "../../src/libraries/Check.sol";

// Wrapper contract to make library calls "real" calls
contract CheckWrapper {
    function validateOnlyLettersAndSpaces(string memory input) external pure {
        Check.validateOnlyLettersAndSpaces(input);
    }
}

contract CheckTest is Test {
    CheckWrapper wrapper;
    
    function setUp() public {
        wrapper = new CheckWrapper();
    }
    
    function testCapitalizeFirstLetters() public pure {
        assertEq(Check.capitalizeFirstLetters("john doe"), "John Doe");
        assertEq(Check.capitalizeFirstLetters("JOHN DOE"), "John Doe");
        assertEq(Check.capitalizeFirstLetters("john"), "John");
    }
    
    function testValidateOnlyLettersAndSpaces_Valid() public view {
        wrapper.validateOnlyLettersAndSpaces("John Doe");  // Should not revert
    }
    
    function testValidateOnlyLettersAndSpaces_InvalidNumber() public {
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "John123"));
        wrapper.validateOnlyLettersAndSpaces("John123");  // Call through wrapper
    }
    
    function testValidateOnlyLettersAndSpaces_Empty() public {
        vm.expectRevert(Check.EmptyInput.selector);
        wrapper.validateOnlyLettersAndSpaces("");  // Call through wrapper
    }
}