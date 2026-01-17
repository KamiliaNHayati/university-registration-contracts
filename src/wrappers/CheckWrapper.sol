// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "../libraries/Check.sol";

contract CheckWrapper {
    using Check for string;

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return a.compareStrings(b);
    }

    function checkCapitalLetters(string memory a) public pure returns (string memory){
        return a.capitalizeFirstLetters();
    }

    function middleDigitsNum(string memory numbers) public pure returns (bool isValid, string memory errorMessage){
        return numbers.validateMiddleDigits();
    }

    function stringToUint(string memory number) public pure returns (uint){
        return number.stringToUint();
    }
}