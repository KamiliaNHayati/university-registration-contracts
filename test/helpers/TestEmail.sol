// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {Email} from "../../src/libraries/Email.sol";

contract EmailTest {
    
    using Email for string;

    function testLowerCase(string memory a) public pure returns (string memory) {
        return a.toLowerCase();
    }

    function testConvertSpacesToDots(string memory a) public pure returns (string memory) {
        return Email.convertSpacesToDots(a);
    }
}