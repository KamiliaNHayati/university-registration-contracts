// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Email {
    // // // _toLowercase are from https://gist.github.com/ottodevs/c43d0a8b4b891ac2da675f825b1d1dbf?permalink_comment_id=4976821#gistcomment-4976821
    // // // The code has been slightly modified

    function toLowercase(string memory inputNonModifiable) public pure returns (string memory) {
        bytes memory input = bytes(inputNonModifiable);

        for (uint i = 0; i < input.length; i++) {   

            if(input[i] >= "A" && input[i] <= "Z"){
                input[i] = bytes1(uint8(input[i]) + 32);
            }
        }
        return string(input);
    }

    function convertSpacesToDots(string memory inputNonModifiable) internal pure returns (string memory){
        bytes memory input = bytes(inputNonModifiable);

        for(uint i = 0; i < input.length; i++){
            if(input[i] == " "){
                input[i] = ".";
            }
        }
        return string(input);
    }

}

