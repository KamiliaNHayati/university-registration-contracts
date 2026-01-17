// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Check} from "../../src/libraries/Check.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {FacultyHelper} from "../helpers/TestFacultyAndMajor.sol";

contract FacultyAndMajorTest is Test {
    FacultyAndMajor public facultyAndMajor;
    // FacultyHelper public facultyAndMajor;

    function setUp() public {
        facultyAndMajor = new FacultyAndMajor();
        // facultyAndMajor = new FacultyHelper();
    }

    function testAddFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addFaculty("Fakultas Agama Islam", "FAI");
        assertEq(facultyAndMajor.listFaculties().length, 2);
    }

    function testUpdateFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.updateFaculty("Fakultas Teknik", "Fakultas Ilmu Komputer", "FIK");
        assertEq(facultyAndMajor.listFaculties().length, 1, "Should have 1 major in the faculty");
    }

    function testRemoveFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.removeFaculty("Fakultas Teknik");
        assertEq(facultyAndMajor.listFaculties().length, 0);
    }

    function testAddMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        
        string[] memory majors = facultyAndMajor.listMajors("Fakultas Teknik");
        console.log("After adding major - Number of majors:", majors.length);
        if (majors.length > 0) {
            console.log("First major name:", majors[0]);
        }
        // Assertions
        assertGt(majors.length, 0, "Should have at least one major");
        assertEq(majors[0], "Teknik Informatika", "Major name should match");
    }

    function testUpdateMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        facultyAndMajor.updateMajor("Fakultas Teknik", "Teknik Informatika", "Sistem Informasi", "1080", 100);
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik").length, 1);
    }

    function testRemoveMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        facultyAndMajor.removeMajor("Fakultas Teknik", "Teknik Informatika");
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik").length, 0);
    }

    function testGetAbbreviation() public{
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        assertEq(facultyAndMajor.getAbbreviation("Fakultas Teknik"), "FT");
    }

    function testGetMiddleNumOfTheMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        assertEq(Check.stringToUint(facultyAndMajor.getMajorMiddleNum("Fakultas Teknik", "Teknik Informatika")), 1408);
    }

    function testCostAnotherContract() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        assertEq(facultyAndMajor.getMajorCost("Fakultas Teknik", "Teknik Informatika"), 100);
    }

    function testIncreaseStudentCount() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        facultyAndMajor.incrementStudentCount("Fakultas Teknik", "Teknik Informatika");
        (, , , uint16 studentCount, ) = facultyAndMajor.getMajorDetails("Fakultas Teknik", "Teknik Informatika");
        assertEq(studentCount, 1);
    } 

    function testDecreaseStudentCount() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        facultyAndMajor.incrementStudentCount("Fakultas Teknik", "Teknik Informatika");
        facultyAndMajor.decrementStudentCount("Fakultas Teknik", "Teknik Informatika");
        (, , , uint16 studentsCount, ) = facultyAndMajor.getMajorDetails("Fakultas Teknik", "Teknik Informatika");
        assertEq(studentsCount, 0);    
    }

    function testGetMajorOfTheFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1408", 100);
        facultyAndMajor.addMajor("Fakultas Teknik", "Sistem Informasi", "1409", 100);
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik").length, 2);
    }

    function testGetAllFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addFaculty("Fakultas Ilmu Komputer", "FIK");
        assertEq(facultyAndMajor.listFaculties().length, 2);
    }

    // function testRevertOnInvalidMiddleDigits() public {
    //     facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        
    //     // Test for too short middle digits
    //     vm.expectRevert("Input terlalu pendek");
    //     facultyAndMajor.addMajor("Fakultas Teknik", "Sistem Informasi", "230", 100);

    //     // Test for too long middle digits
    //     vm.expectRevert("Input terlalu panjang");
    //     facultyAndMajor.addMajor("Fakultas Teknik", "Sistem Informasi", "23011", 100);
    // }
}        