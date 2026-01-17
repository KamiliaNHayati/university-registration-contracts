// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {ForOwners} from "../../src/access/CostumizedContract.sol";

contract CostumizedContractTest is Test{

    IFacultyAndMajor private facultyAndMajor;
    ForOwners private forOwners;

    function setUp() public {
        facultyAndMajor = new FacultyAndMajor();
        forOwners = new ForOwners(address(facultyAndMajor));
    }

    function testAddFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        assertEq(facultyAndMajor.listFaculties().length, 1);
    }

    function testAddMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik").length, 0);
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "0140", 1241);
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik").length, 1);
    }

    function testUpdateFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.updateFaculty("Fakultas Teknik", "Fakultas Ilmu Komputer", "FIK");
        assertEq(facultyAndMajor.listFaculties()[0], "Fakultas Ilmu Komputer");
    }

    function testRemoveFaculty() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.removeFaculty("Fakultas Teknik");
        assertEq(facultyAndMajor.listFaculties().length, 0);
    }

    function testUpdateMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "0140", 1040);
        facultyAndMajor.updateMajor("Fakultas Teknik", "Teknik Informatika", "Sistem Informasi", "0921", 200);
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik")[0], "Sistem Informasi");
    }

    function testRemoveMajor() public {
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "0140", 1040);
        facultyAndMajor.removeMajor("Fakultas Teknik", "Teknik Informatika");
        assertEq(facultyAndMajor.listMajors("Fakultas Teknik").length, 0);
    }


}