// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";

library Check {

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        assembly {
            let lenA := mload(a)
            let lenB := mload(b)
            
            if iszero(eq(lenA, lenB)) {
                mstore(0x00, 0)      // Store false at memory position 0x00
                return(0x00, 0x20)   // Return 32 bytes (one word)
            }
            
            let ptrA := add(a, 0x20)
            let ptrB := add(b, 0x20)
    
            // Compare full words (32 bytes at a time)
            let words := div(add(lenA, 31), 32) // If a string is shorter than 32 bytes, it still takes up one full chunk. If it's longer, it occupies multiple 32-byte chunks.
            for { let i := 0 } lt(i, words) { i := add(i, 1) } {
                let wordA := mload(add(ptrA, mul(i, 32))) // When i = 0, we read the first 32 bytes of the string and so on
                let wordB := mload(add(ptrB, mul(i, 32)))

                if iszero(eq(wordA, wordB)) { // In Yul, you don’t have the same syntactic sugar as in higher-level languages (like writing if (wordA != wordB)). Instead, you use built-in functions like these : (isZero and eq)
                    mstore(0x00, 0)      // Store false at memory position 0x00
                    return(0x00, 0x20)   // Return 32 bytes (one word)
                }
            }
            // All words match; return true.
            mstore(0x00, 1)
            return(0x00, 0x20) // return 0 bytes from memory address 1. return(adddress, size)
        }
    }

    function capitalizeFirstLetters(string memory name) internal pure returns (string memory) { // it will be input to front end code
        bytes memory bytesInput = bytes(name);
        
        assembly {
            // Load the length of the string
            let length := mload(bytesInput)
            
            // Point to the start of the string data (skip the length field)
            let ptr := add(bytesInput, 0x20)
            
            // Loop through each character in the string
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                // Load the current character
                let char := byte(0, mload(add(ptr, i)))

                // Check if the character is a valid ASCII character (32–126)
                if iszero(or(eq(char, 32), or(and(gt(char, 64), lt(char, 91)), and(gt(char, 96), lt(char, 123))))) {
                    // Standard ABI error encoding for string errors
                    mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    
                    // Pointer to error message
                    mstore(0x04, 0x20)
                    
                    // Message length (exactly 24 bytes)
                    mstore(0x24, 0x18)  // 24 bytes
                    
                    // Store full error message with careful spacing
                    mstore(0x44, "Only alphabets and space")
                    
                    // Revert with error
                    revert(0x00, 0x64)
                }
                                
                // Check if it's the first character and a lowercase letter (97–122)
                if and(eq(i, 0), and(gt(char, 96), lt(char, 123))) {
                    // Convert to uppercase by subtracting 32
                    mstore8(add(ptr, i), sub(char, 32))
                }
                
                // Check the previous character (if it exists)                
                if gt(i, 0){
                    let prevChar := byte(0, mload(add(ptr, sub(i, 1))))

                    // Check if the previous character is a space
                    if eq(prevChar, 32) {
                       // If the current character is a lowercase letter, convert it to uppercase
                        if and(gt(char, 96), lt(char, 123)){
                            mstore8(add(ptr,i), sub(char, 32))
                        }
                    }
                }
            }
        }
        
        return string(bytesInput);
    }
    // nanti di bagian front end jg ditambahin pengecekan klo dia ga nambahin kata Fakutlas nnt ditmbhin lg

    function validateMiddleDigits(string memory inputMiddleNum) internal pure returns (bool isValid, string memory errorMessage) {
        bytes memory middleNum = bytes(inputMiddleNum);
        uint length = middleNum.length;
        
        if(length > 4) return (false, "Input terlalu panjang");
        if(length < 4) return (false, "Input terlalu pendek");
        
        return (true, "");
    }
    // This version is slightly more gas-efficient (about 200 gas less than the Solidity version
    // function middleDigitsNim(string memory input) external pure returns (bool){
    //     bytes memory middleNim = bytes(input);
    //     assembly {
    //         let length := mload(middleNim)
    //         if gt(length, 4){
    //             mstore(0x00, 0)
    //             return(0x00, 0x20)
    //         }
    //         mstore(0x00, 1)
    //         return(0x00, 0x20)
    //     }
    // }

    // function checkMonth() external view returns (bool){
    //     uint monthEnrollment = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);
    //     if (monthEnrollment <= 8 || monthEnrollment > 9) {
    //         return true;
    //     }
    //     return false;
    // }

    function stringToUint(string memory str) internal pure returns (uint) {
        bytes memory b = bytes(str);
        uint result;
        
        assembly {
            // Get the length of the string
            let length := mload(b)
            // Point to the first character
            let ptr := add(b, 0x20)
            
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                // Load current character
                let char := byte(0, mload(add(ptr, i)))
                // Convert ASCII to number (48 is '0' in ASCII)
                let digit := sub(char, 48)
                
                // Check if char is a valid digit (0-9)
                if or(lt(digit, 0), gt(digit, 9)) {
                    // Revert with error message
                    mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x04, 0x20)
                    mstore(0x24, 18)
                    mstore(0x44, "Invalid number str")
                    revert(0x00, 0x64)
                }
                
                // result = result * 10 + digit
                result := add(mul(result, 10), digit)
            }
        }
        
        return result;
    }
}