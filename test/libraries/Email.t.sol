// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {EmailTest} from "../helpers/TestEmail.sol";

contract EmailTest2 is Test{
    
    EmailTest public emailTest;

    function setUp() public {
        emailTest = new EmailTest();
    }

    function testToLowercaseInline() public view {
        assertEq(emailTest.testLowerCase("Rizky"), "rizky");
    }

    function testChangeSpaceFromLowerCase() public view {
        assertEq(emailTest.testConvertSpacesToDots("Rizky Koko"), "rizky.koko.");
    }
}