// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IStudents} from "../../src/interfaces/IStudents.sol";
import {IRoleManager} from "../../src/interfaces/IRoleManager.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {MyContract} from "../../src/access/Ownable.sol";
import {Students} from "../../src/core/Students.sol";
import {Check} from "../../src/libraries/Check.sol";
import {Email} from "../../src/libraries/Email.sol";
import {ContractPublic} from "../../src/access/ContractPublic.sol";

contract ContractPublicTest is Test{

    Students public students;
    FacultyAndMajor private facultyAndMajor;
    IRoleManager public roleManager;
    MyContract private myContract;
    ContractPublic private contractPublic;

    
    function setUp() public {
        facultyAndMajor = new FacultyAndMajor();
        students = new Students(address(facultyAndMajor));
        myContract = new MyContract();
        roleManager = IRoleManager(address(myContract));
        contractPublic = new ContractPublic(address(students), address(myContract));
        // contractPublic = new ContractPublic(address(myContract), address(students));
    }
    
    function testAddStudentsandGetStudent() public {
        address userAddress = address(0x123);
        vm.deal(userAddress, 2 ether);
        vm.startPrank(userAddress);

        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "1010", 1000000000000000000);
        contractPublic.enrollNewStudent{value: 1 ether}(
            "Rizky",              // name
            "Fakultas Teknik",    // faculty
            "Teknik Informatika"  // major
        );

        // Now you can verify the student was added, etc.
        // For example, if there's a getStudents function in Students:
        (string memory name, , , , , ) = contractPublic.getStudentInfo();
        vm.stopPrank();

        assertEq(name, "Rizky", "The student name should be Rizky");
    }

    // function testChangeStatus() public {
    //     facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
    //     facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "TI", 100);
    //     students.addStudent("Rizky", "Fakultas Teknik", "Teknik Informatika");
    //     students.changeStatus("Rizky");
    //     assertNotEq(students.getStudents().status, "Active");
    // }

    function testChangeStatus() public {
        // Set up a test address
        address userAddress = address(0x123);
        
        // Creates a test address 0x123, gives it 2 ETH using Foundry's vm.deal
        vm.deal(userAddress, 2 ether);

        // Impersonate the user
        vm.startPrank(userAddress);
        
        facultyAndMajor.addFaculty("Fakultas Teknik", "FT");
        facultyAndMajor.addMajor("Fakultas Teknik", "Teknik Informatika", "2030", 1000000000000000000);
        contractPublic.enrollNewStudent{value: 1 ether}(
            "Rizky",              // name
            "Fakultas Teknik",    // faculty
            "Teknik Informatika"  // major
        );
        
        // Change the student's status
        contractPublic.processDropout("Rizky");

        // Get the updated student info
        (, , , , , string memory status) = contractPublic.getStudentInfo();
        
        // Stop impersonating
        vm.stopPrank();
        
        // Check that status changed - use positive assertions when possible
        assertEq(status, "Dropout");
    }}


