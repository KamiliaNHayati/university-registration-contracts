// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";

library Check {

    error OnlyLettersAndSpaces();
    error EmptyInput();
    error TooLongCode();
    error TooShortCode();

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function capitalizeFirstLetters(string memory name) internal pure returns (string memory) {
        bytes memory b = bytes(name);
        bool capitalizeNext = true;
        
        // Check empty first
        if (b.length == 0) revert EmptyInput();
        
        // Then check characters
        for (uint i = 0; i < b.length; i++) {
            if (b[i] == " ") {
                capitalizeNext = true;
            } else if (capitalizeNext && b[i] >= "a" && b[i] <= "z") {
                b[i] = bytes1(uint8(b[i]) - 32);
                capitalizeNext = false;
            } else if (!capitalizeNext && b[i] >= "A" && b[i] <= "Z") {
                b[i] = bytes1(uint8(b[i]) + 32);
            } else {
                capitalizeNext = false;
            }
        }
        return string(b);
    }

    function validateLengthCode(string memory inputCode, uint32 maxLength) internal pure returns (bool isValid) {
        bytes memory code = bytes(inputCode);
        uint length = code.length;
        
        if(length > maxLength) revert TooLongCode();
        else if(length < maxLength) revert TooShortCode();
        
        return (true);
    }

    function validateOnlyLettersAndSpaces(string memory input) internal pure{
        bytes memory b = bytes(input);
        for (uint i = 0; i < b.length; i++) {
            if (!((b[i] == " ") || (b[i] >= "A" && b[i] <= "Z") || (b[i] >= "a" && b[i] <= "z"))) {
                revert OnlyLettersAndSpaces();
            }
        }
    }
}