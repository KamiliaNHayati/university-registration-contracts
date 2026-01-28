// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Email {
    // // // _toLowercase are from https://gist.github.com/ottodevs/c43d0a8b4b891ac2da675f825b1d1dbf?permalink_comment_id=4976821#gistcomment-4976821
    // // // The code has been slightly modified

    function toLowercase(string memory inputNonModifiable) internal pure returns (string memory) {
        bytes memory original = bytes(inputNonModifiable);
        bytes memory result = new bytes(original.length);  // Create NEW copy

        for (uint i = 0; i < original.length; i++) {   
            if(original[i] >= "A" && original[i] <= "Z"){
                result[i] = bytes1(uint8(original[i]) + 32);
            } else {
                result[i] = original[i];
            }
        }
        return string(result);
    }

    function convertSpacesToDots(string memory inputNonModifiable) internal pure returns (string memory) {
        bytes memory input = bytes(toLowercase(inputNonModifiable));
        uint spaceCount;
        uint endIndex = input.length;
        
        for(uint i = 0; i < input.length; i++){
            if(input[i] == " "){
                if(spaceCount < 2){
                    input[i] = ".";
                    spaceCount++;
                } else {
                    // Found 3rd space, truncate here
                    endIndex = i;
                    break;
                }
            }
        }
        
        // Create shorter array if truncated
        bytes memory result = new bytes(endIndex);
        for(uint i = 0; i < endIndex; i++){
            result[i] = input[i];
        }
        return string(result);
    }

}

