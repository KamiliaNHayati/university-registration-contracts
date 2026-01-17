// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Email {
    // // // _toLowercase are from https://gist.github.com/ottodevs/c43d0a8b4b891ac2da675f825b1d1dbf?permalink_comment_id=4976821#gistcomment-4976821
    // // // The code has been slightly modified
    // function _toLowercase2(string memory inputNonModifiable) public pure returns (string memory) {
    //     bytes memory bytesInput = bytes(inputNonModifiable);

    //     for (uint i = 0; i < bytesInput.length; i++) {
    //         // checks for valid ascii characters // will allow unicode after building a string library
    //         require (uint8(bytesInput[i]) > 31 && uint8(bytesInput[i]) < 127, "Only ASCII characters");
    //         // Uppercase character...
    //         if (uint8(bytesInput[i]) > 64 && uint8(bytesInput[i]) < 91) {
    //             // add 32 to make it lowercase
    //             bytesInput[i] = bytes1(uint8(bytesInput[i]) + 32);
    //         }
    //     }
    //     return string(abi.encodePacked(bytesInput));
    // }
    
    function toLowerCase(string memory inputNonModifiable) internal pure returns (string memory) { // i will put this on front-end code
        
        // Convert the input string to bytes for manipulation
        bytes memory bytesInput = bytes(inputNonModifiable);

        assembly {
            // Get the length of the input string
            let length := mload(bytesInput) // the data is stored left to right (e.g 0x20: H | e | l | l | o | ... (remaining bytes unused))
            // Pointer to the actual data (skip the first 32 bytes which store the length)
            let ptr := add(bytesInput, 0x20)

            // Iterate over each byte in the string
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                // Load the current byte
                let char := byte(0, mload(add(ptr, i))) // The 0 means we want the leftmost (most significant) byte

                // Check if the character is a valid ASCII character (32–126)
                if iszero(or(eq(char,32), or(and(gt(char, 64), lt(char, 91)), and(gt(char, 96), lt(char,123))))) {
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

                // Check if the character is uppercase (65–90)
                if and(gt(char, 64), lt(char, 91)) {
                    // Convert to lowercase by adding 32
                    mstore8(add(ptr, i), add(char, 32))
                }
            }
        }
        // Return the modified string
        return string(bytesInput);
    }

    function convertSpacesToDots(string memory input) internal pure returns (string memory){ // i will put this on front-end code
        bytes memory bytesInput = bytes(toLowerCase(input)); 
        bytes memory resultTemp;

        assembly {
            let length := mload(bytesInput)
            let newLength := length

            resultTemp := mload(0x40)
            mstore(resultTemp, length)
            let sourcePtr := add(bytesInput, 0x20)
            let resultPtr := add(resultTemp, 0x20)

            let j := 0
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let char := byte(0, mload(add(sourcePtr, i)))

                if eq(char, 32) { // Space (' ')
                    mstore8(resultPtr, 46) // Store '.'
                    resultPtr := add(resultPtr, 1)
                    if gt(j, 2) { 
                        break 
                    } // Stop after replacing 2 spaces
                    j := add(j, 1)
                    continue
                }
                mstore8(resultPtr, char)
                resultPtr := add(resultPtr, 1)
            }

            // add dot after processing all character
            mstore8(resultPtr, 46)     
            resultPtr := add(resultPtr, 1)
        
            // Calculate the actual length of the result
            let actualLength := sub(resultPtr, add(resultTemp, 0x20))
            // Update the length of the result array
            mstore(resultTemp, actualLength)

            // Update the free memory pointer
            mstore(0x40, resultPtr)        
        }
        return string(resultTemp);
    }

    // function changeSpaceFromLowerCase(string memory input) public pure returns (string memory){
    //     bytes memory copy = bytes(_toLowercaseInline(input)); 
    //     bytes memory resultTemp = bytes(_toLowercaseInline(input));
    //     uint j = 0;
    //     uint length = copy.length;
    //     for(uint i = 0; i < length; i++){
    //         uint256 b = uint256(uint8(copy[i]));
    //         require(b >= 32 || b >= 97 || b < 123, "Only space and lowercase"); // kalau ini bakal muncul peringatan mending g usah
    //         if(b == 32) {
    //             resultTemp[i] = bytes1(uint8(46));                
    //             if (j > 2){
    //                 break;
    //             }
    //             j++;
    //             continue;
    //         }
    //         resultTemp[i] = copy[i];
    //     }
    //     return string(abi.encodePacked(resultTemp, "."));
    // }

    // function setYear() internal view returns (uint){
    //     uint yearCreated = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);
    //     return yearCreated % 100;     
    // }   
}

