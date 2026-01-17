// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import {Check} from "../../src/libraries/Check.sol";
// import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";

contract FacultyHelper is FacultyAndMajor {
    
    function getStructMajorOfTheFaculty(uint iterationFaculty, string memory major) public view returns (uint) {
        return facultyList[iterationFaculty].majors[major].studentCount;
    }

}