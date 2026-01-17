// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {Check} from "../../src/libraries/Check.sol";

contract CheckTest {
    
    using Check for string;

    function testCompareStrings(string memory a, string memory b) public pure returns (bool) {
        return a.compareStrings(b);
    }

    function testCapitalizeFirstLetters(string memory a) public pure returns (string memory){
        return a.capitalizeFirstLetters();
    }

    function testValidateMiddleDigits(string memory numbers) public pure returns (bool isValid, string memory errorMessage){
        return numbers.validateMiddleDigits();
    }

    function testStringToUint(string memory number) public pure returns (uint){
        return number.stringToUint();
    }
}