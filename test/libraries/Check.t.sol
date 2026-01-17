// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {CheckTest} from "../helpers/TestCheck.sol";

contract CheckTest2 is Test{
    
    CheckTest public checkTest;

    function setUp() public {
        checkTest = new CheckTest();
    }

    function testCompareStrings() public view {
        assertEq(checkTest.testCompareStrings("Rizky", "Rizky"), true);
    }

    function testCheckCapitalLetters() public view {
        assertEq(checkTest.testCapitalizeFirstLetters("Rizky"), "Rizky");
    }

    function testMiddleDigitsNum() public view {
        (bool result, ) = checkTest.testValidateMiddleDigits("12345");
        assertEq(result, false);
    }

    function testStringToUint() public view {
        assertEq(checkTest.testStringToUint("123456"), 123456);
    }
}