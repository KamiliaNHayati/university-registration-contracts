// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {IStudents} from "../../src/interfaces/IStudents.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {Students} from "../../src/core/Students.sol";
import {Check} from "../../src/libraries/Check.sol";
import {Email} from "../../src/libraries/Email.sol";

contract StudentsTest is Test{

    IStudents public students;
    IFacultyAndMajor public facultyAndMajor;

    function setUp() public {
        facultyAndMajor = new FacultyAndMajor();
        students = new Students(address(facultyAndMajor));
    }

    modifier startAtPresentDay() {
        vm.warp(1741510139);
        _;
    }

    function testCheckingCost() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1480", 100);
        assertEq(students.getMajorCost("Fakultas Teknik", "Teknik Informatika"), 100);
    }

    function testAddStudentsAndGetStudent() public startAtPresentDay{
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1480", 100);
        address sender = msg.sender;
        uint256 valueToSend = 100;
        students.enrollStudent(valueToSend, sender, "Rizky", "Fakultas Teknik", "Teknik Informatika");
        (string memory name, , , , , ) = students.getStudent(sender);
        assertEq(name, "Rizky");
    }

    function testChangeStatus() public startAtPresentDay{
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1480", 100);
        address sender = msg.sender;        
         uint256 valueToSend = 100;
        students.enrollStudent(valueToSend, msg.sender, "Rizky", "Fakultas Teknik", "Teknik Informatika");
        students.processStudentDroput(sender, "Rizky");
        (, , , , ,string memory status) = students.getStudent(sender);
        assertNotEq(status, "Activate");
    }
}


