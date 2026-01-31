// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Check} from "../../src/libraries/Check.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {FacultyAndMajorScript} from "../../script/FacultyAndMajor.s.sol";

contract FacultyAndMajorTest is Test{

    /*//////////////////////////////////////////////////////////////
                              EVENT
    //////////////////////////////////////////////////////////////*/
    event NewFaculty(uint indexed facultyId, string facultyName, string facultyCode);
    event UpdateFaculty(uint indexed facultyId, string oldName, string newName, string newFacultyCode);
    event RemoveFaculty(uint indexed facultyId, string facultyName);

    event NewMajor(uint indexed facultyId, uint indexed majorId, string majorName, string majorCode, uint16 maxEnrollment, uint cost);
    event UpdateMajor(uint indexed facultyId, uint indexed majorId, string oldName, string newName, string newMajorCode, uint16 newMaxEnrollment, uint newCost);
    event RemoveMajor(uint indexed facultyId, uint indexed majorId, string majorName);

    event MaxLengthFacultyCodeUpdated(uint32);
    event MaxLengthMajorCodeUpdated(uint32);
    event StudentsContractUpdated(address studentsContract);
    event UniversityNameUpdated(string universityName);
    /*//////////////////////////////////////////////////////////////
                              STATE
    //////////////////////////////////////////////////////////////*/
    FacultyAndMajor public facultyAndMajor;
    string facultyName = "School of Computing";
    string formattedName = Check.capitalizeFirstLetters(facultyName);
    string newFacultyName = "School of Engineering";
    string formattedNewFacultyName = Check.capitalizeFirstLetters(newFacultyName);
    string facultyCode = "1200";
    string newFacultyCode = "1300";
    string majorName = "Information Technology";
    string formattedMajorName = Check.capitalizeFirstLetters(majorName);
    string newMajorName = "Cyber Security";
    string formattedNewMajorName = Check.capitalizeFirstLetters(newMajorName);
    string majorCode = "1201";
    string newMajorCode = "1202";
    uint16 maxEnrollment = 100;
    uint cost = 0.8 ether;
    address public owner;

    function setUp() public {
        FacultyAndMajorScript facultyAndMajorScript = new FacultyAndMajorScript();
        facultyAndMajor = facultyAndMajorScript.run("Nusantara University", 4, 4);

        owner = facultyAndMajor.owner();
    }

    /*//////////////////////////////////////////////////////////////
                              HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/
    function _addFacultyAndMajor() internal {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);
    }

    /*//////////////////////////////////////////////////////////////
                              ADD FACULTY
    //////////////////////////////////////////////////////////////*/

    function testAddFaculty_RevertsWhenFacultyNameIsInvalid() public {
        vm.expectRevert(Check.EmptyInput.selector);
        vm.prank(owner);
        facultyAndMajor.addFaculty("", "123");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));  
        facultyAndMajor.addFaculty("123", "123");
    }

    function testAddFaculty_Success() public {
        vm.prank(owner); 
        facultyAndMajor.addFaculty(facultyName, facultyCode);
        assertEq(facultyAndMajor.listFaculties().length, 1);
    }

    function testAddFaculty_WhenFacultyAlreadyExist() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyAlreadyExists.selector, formattedName));
        facultyAndMajor.addFaculty(facultyName, facultyCode);
    }

    function testAddFaculty_WhenFacultyCodeIsLessThan4() public {
        vm.prank(owner);
        vm.expectRevert(Check.TooShortCode.selector);  
        facultyAndMajor.addFaculty(facultyName, "120");
    }
    
    function testAddFaculty_WhenFacultyCodeIsMoreThan4() public {
        vm.prank(owner);
        vm.expectRevert(Check.TooLongCode.selector);  
        facultyAndMajor.addFaculty(facultyName, "12000");
    }

    function testAddFaculty_StoresFacultyCode() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        assertEq(facultyAndMajor.getFacultyCode(formattedName), facultyCode);
    }

    function testAddFaculty_EmitsEvent() public {
        vm.expectEmit(true, false, false, true, address(facultyAndMajor));
        emit NewFaculty(1, formattedName, facultyCode);        
        
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);
    }

    /*//////////////////////////////////////////////////////////////
                           UPDATE FACULTY
    //////////////////////////////////////////////////////////////*/

    function testUpdateFaculty_WhenFacultyNameIsInvalid() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);  // Add valid faculty first

        vm.expectRevert(Check.EmptyInput.selector);
        vm.prank(owner);
        facultyAndMajor.updateFaculty("", newFacultyName, newFacultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));  
        facultyAndMajor.updateFaculty("123", newFacultyName, newFacultyCode);  // First param invalid
    }

    function testUpdateFacultyReverts_WhenNewNameIsInvalid() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);  // Add valid faculty first
        
        vm.expectRevert(Check.EmptyInput.selector);
        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, "", newFacultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));  
        facultyAndMajor.updateFaculty(facultyName, "123", newFacultyCode);  // Second param invalid
    }

    function testUpdateFaculty_Success() public {
        vm.prank(owner); 
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, newFacultyName, newFacultyCode);
        assertEq(facultyAndMajor.getFacultyCode(formattedNewFacultyName), newFacultyCode);
    }

    function testUpdateFaculty_WhenFacultyNotExist() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, formattedName));
        facultyAndMajor.updateFaculty(facultyName, newFacultyName, newFacultyCode);
    }

    function testUpdateFaculty_UpdatesExistingFaculty() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(formattedName, newFacultyName, newFacultyCode);
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties[0], formattedNewFacultyName);
        assertEq(facultyAndMajor.getFacultyCode(formattedNewFacultyName), newFacultyCode);
    }

    function testUpdateFaculty_RevertsWhenCodeTooShort() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(Check.TooShortCode.selector);
        facultyAndMajor.updateFaculty(facultyName, "Engineering", "130");
    }

    function testUpdateFaculty_RevertsWhenCodeTooLong() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(Check.TooLongCode.selector);
        facultyAndMajor.updateFaculty(facultyName, "Engineering", "13000");
    }

    function testUpdateFaculty_OnlyChangesCode() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, "Engineering", facultyCode);

        assertEq(facultyAndMajor.getFacultyCode("Engineering"), facultyCode);
    }

    function testUpdateFaculty_NoChanges() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, facultyName, facultyCode);
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties[0], formattedName);
        assertEq(facultyAndMajor.getFacultyCode(formattedName), facultyCode);
    }

    function testUpdateFaculty_NewNameAndCode() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, newFacultyName, facultyCode);

        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties[0], formattedNewFacultyName);
        assertEq(facultyAndMajor.getFacultyCode(formattedNewFacultyName), facultyCode);
    }

    function testUpdateFaculty_NewName() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, newFacultyName, facultyCode);
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties[0], formattedNewFacultyName);
        assertEq(facultyAndMajor.getFacultyCode(formattedNewFacultyName), facultyCode);
    }

    function testUpdateFaculty_NewCode() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, facultyName, newFacultyCode);
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties[0], formattedName);
        assertEq(facultyAndMajor.getFacultyCode(formattedName), newFacultyCode);
    }

    function testUpdateFaculty_EmitsEvent() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.expectEmit(true, false, false, true, address(facultyAndMajor));
        emit UpdateFaculty(1, formattedName, formattedNewFacultyName, newFacultyCode);

        vm.prank(owner);
        facultyAndMajor.updateFaculty(facultyName, newFacultyName, newFacultyCode);
    }

    /*//////////////////////////////////////////////////////////////
                              REMOVE FACULTY
    //////////////////////////////////////////////////////////////*/

    function testRemoveFaculty_RevertsWhenFacultyNameIsInvalid() public {
        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.removeFaculty("");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));  
        facultyAndMajor.removeFaculty("123");
    }

    function testRemoveFaculty_Success() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);
        
        vm.prank(owner);
        facultyAndMajor.removeFaculty(facultyName);

        assertEq(facultyAndMajor.listFaculties().length, 0);
    }

    function testRemoveFaculty_RevertsWhenFacultyNotFound() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, "Nonexistent Faculty"));
        facultyAndMajor.removeFaculty("Nonexistent Faculty");
    }

    function testRemoveFaculty_RevertsWhenFacultyHasMajors() public {
        _addFacultyAndMajor();
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorAlreadyExists.selector, "Faculty still has majors"));
        facultyAndMajor.removeFaculty(facultyName);
    }

    function testRemoveFaculty_SuccessWhenNoMajors() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.removeFaculty(facultyName);
        assertEq(facultyAndMajor.listFaculties().length, 0);
    }

    function testRemoveFaculty_SwapVerification() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);  // Will be at index 0
        
        vm.prank(owner);
        facultyAndMajor.addFaculty(newFacultyName, newFacultyCode);  // Will be at index 1
    
        vm.prank(owner);
        facultyAndMajor.removeFaculty(facultyName);  // Remove first, second moves to index 0
    
        // Verify the swap worked correctly
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties.length, 1);
        assertEq(faculties[0], formattedNewFacultyName);  // Second faculty now at index 0
    }

    // Test removing NOT last faculty (if branch - line 140)
    function testRemoveFaculty_NotLastFaculty() public {
        // Add two faculties
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);
        
        vm.prank(owner);
        facultyAndMajor.addFaculty(newFacultyName, newFacultyCode);
        
        // Remove first one (not last)
        vm.prank(owner);
        facultyAndMajor.removeFaculty(facultyName);
        
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties.length, 1);
        assertEq(faculties[0], formattedNewFacultyName);
    }

    // Test removing LAST faculty (else branch - line 140)
    function testRemoveFaculty_LastFaculty() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);
    
        vm.prank(owner);
        facultyAndMajor.removeFaculty(facultyName);
        
        string[] memory faculties = facultyAndMajor.listFaculties();
        assertEq(faculties.length, 0);
    }

    function testRemoveFaculty_EmitsEvent() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.expectEmit(true, false, false, true, address(facultyAndMajor));
        emit RemoveFaculty(1, formattedName);

        vm.prank(owner);
        facultyAndMajor.removeFaculty(facultyName);
    }

    /*//////////////////////////////////////////////////////////////
                              ADD MAJOR
    //////////////////////////////////////////////////////////////*/
    function testAddMajor_WhenFacultyNameIsInvalid() public {
        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.addMajor("", majorName, majorCode, maxEnrollment, cost);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.addMajor("123", majorName, majorCode, maxEnrollment, cost);
    }

    function testAddMajor_WhenFacultyNameOnlyLettersAndSpace() public {
        _addFacultyAndMajor();

        assertEq(facultyAndMajor.listMajors(facultyName).length, 1);
    }

    function testAddMajor_WhenMajorNameIsInvalid() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.addMajor(facultyName, "123", majorCode, maxEnrollment, cost);
    }

    function testAddMajor_WhenMajorNameOnlyLettersAndSpace() public {
        _addFacultyAndMajor();

        assertEq(facultyAndMajor.listMajors(facultyName).length, 1);
    }

    function testAddMajor_WhenFacultyNotFound() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, formattedName));
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);
    }

    function testAddMajor_WhenFacultyExist() public {
        _addFacultyAndMajor();

        uint256 majorCostResult = facultyAndMajor.getMajorCost(facultyName, majorName);
        assertEq(majorCostResult, cost);
    }

    function testAddMajor_WhenMajorAlreadyExist() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorAlreadyExists.selector, formattedMajorName));
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);
    }

    function testAddMajor_WhenLengthMajorCodeIsMoreThan4() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(Check.TooLongCode.selector);
        facultyAndMajor.addMajor(facultyName, majorName, "12345", maxEnrollment, cost);
    }

    function testAddMajor_WhenLengthMajorCodeIsLessThan4() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(Check.TooShortCode.selector);
        facultyAndMajor.addMajor(facultyName, majorName, "123", maxEnrollment, cost);
    }

    function testAddMajor_OnlyChangesCode() public {
        _addFacultyAndMajor();
        string memory majorCodeResult = facultyAndMajor.getMajorCode(facultyName, majorName);
        assertEq(majorCodeResult, majorCode);
    }

    function testAddMajor_EmitsEvent() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.expectEmit(true, false, false, true, address(facultyAndMajor));
        emit NewMajor(1, 1, formattedMajorName, majorCode, maxEnrollment, cost);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);
    }

    /*//////////////////////////////////////////////////////////////
                              UPDATE MAJOR
    //////////////////////////////////////////////////////////////*/
    function testUpdateMajor_WhenFacultyNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.updateMajor("", majorName, newMajorName, newMajorCode, maxEnrollment, cost);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.updateMajor("123", majorName, newMajorName, newMajorCode, maxEnrollment, cost);
    }

    function testUpdateMajor_WhenMajorNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.updateMajor(facultyName, "", newMajorName, newMajorCode, maxEnrollment, cost);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.updateMajor(facultyName, "123", newMajorName, newMajorCode, maxEnrollment, cost);
    }

    function testUpdateMajor_WhenMajorNameOnlyLettersAndSpace() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, newMajorCode, maxEnrollment, cost);
        
        uint256 majorCostResult = facultyAndMajor.getMajorCost(facultyName, newMajorName);
        assertEq(majorCostResult, cost);
    }

    function testUpdateMajor_WhenLengthMajorCodeIsMoreThan4() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.TooLongCode.selector);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, "12345", maxEnrollment, cost);
    }

    function testUpdateMajor_WhenLengthMajorCodeIsLessThan4() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.TooShortCode.selector);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, "123", maxEnrollment, cost);
    }

    function testUpdateMajor_OnlyChangesCode() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, newMajorCode, maxEnrollment, cost);

        string memory majorCodeResult = facultyAndMajor.getMajorCode(facultyName, newMajorName);
        assertEq(majorCodeResult, newMajorCode);
    }

    function testUpdateMajor_WhenFacultyNotExist() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, formattedNewFacultyName));
        facultyAndMajor.updateMajor(newFacultyName, majorName, newMajorName, newMajorCode, maxEnrollment, cost);
    }

    function testUpdateMajor_WhenFacultyExist() public{
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, newMajorCode, maxEnrollment, cost);
        assertEq(facultyAndMajor.listMajors(facultyName).length, 1);        
    }

    function testUpdateMajor_WhenMajorNotExist() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorNotFound.selector, formattedNewMajorName));
        facultyAndMajor.updateMajor(facultyName, newMajorName, newMajorName, newMajorCode, maxEnrollment, cost);
    }

    function testUpdateMajor_WhenMajorNameDifferentThanBefore() public {
        _addFacultyAndMajor();

        vm.recordLogs();
        vm.prank(owner);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, newMajorCode, maxEnrollment, cost);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        Vm.Log memory log = entries[0];
        (string memory majorNameBefore, string memory majorNameAfter, , ,) = abi.decode(
            log.data, 
            (string, string, string, uint16, uint)
        );

        assertNotEq(majorNameBefore, majorNameAfter);
    }

    function testUpdateMajor_WhenMajorNameSameAsBefore() public {
        _addFacultyAndMajor();

        vm.recordLogs();
        vm.prank(owner);
        facultyAndMajor.updateMajor(facultyName, majorName, majorName, majorCode, maxEnrollment, cost);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        Vm.Log memory log = entries[0];
        (string memory majorNameBefore, string memory majorNameAfter, , ,) = abi.decode(
            log.data, 
            (string, string, string, uint16, uint)
        );

        assertEq(majorNameBefore, majorNameAfter);
    }

    function testUpdateMajor_EmitsEvent() public {
        _addFacultyAndMajor();

        vm.expectEmit(true, false, false, true, address(facultyAndMajor));
        emit UpdateMajor(1, 1, formattedMajorName, formattedNewMajorName, newMajorCode, maxEnrollment, cost);

        vm.prank(owner);
        facultyAndMajor.updateMajor(facultyName, majorName, newMajorName, newMajorCode, maxEnrollment, cost);
    }

    /*//////////////////////////////////////////////////////////////
                              REMOVE MAJOR
    //////////////////////////////////////////////////////////////*/
    function testRemoveMajor_WhenFacultyNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.removeMajor("", majorName);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.removeMajor("123", majorName);
    }

    function testRemoveMajor_WhenMajorNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.removeMajor(facultyName, "");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.removeMajor(facultyName, "123");
    }

    function testRemoveMajor_WhenMajorNameOnlyLettersAndSpace() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.removeMajor(facultyName, majorName);

        assertEq(facultyAndMajor.listMajors(facultyName).length, 0);
    }

    function testRemoveMajor_WhenFacultyNotFound() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, formattedName));
        facultyAndMajor.removeMajor(facultyName, majorName);
    }

    function testRemoveMajor_WhenMajorNotFound() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorNotFound.selector, formattedMajorName));
        facultyAndMajor.removeMajor(facultyName, majorName);
    }

    function testRemoveMajor_WhenStillHasStudents() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.incrementStudentCount(formattedName, formattedMajorName);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.HasExistingStudents.selector, "Major still has students"));
        facultyAndMajor.removeMajor(facultyName, majorName);
    }

    function testRemoveMajor_WhenThereIsNoStudents() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.removeMajor(facultyName, majorName);

        assertEq(facultyAndMajor.listMajors(facultyName).length, 0);
    }

    function testRemoveMajor_EmitsEvent() public {
        _addFacultyAndMajor();

        vm.expectEmit(true, false, false, true, address(facultyAndMajor));
        emit RemoveMajor(1, 1, formattedMajorName);

        vm.prank(owner);
        facultyAndMajor.removeMajor(facultyName, majorName);
    }

    /*//////////////////////////////////////////////////////////////
                        SET LENGTH FACULTY CODE
    //////////////////////////////////////////////////////////////*/

    function testSetLengthFacultyCode_WhenLengthIsLessThanMinLength() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.InvalidLengthFacultyCode.selector, 1));
        facultyAndMajor.setLengthFacultyCode(1);
    }

    function testSetLengthFacultyCode_WhenLengthIsMoreThanMaxLength() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.InvalidLengthFacultyCode.selector, 11));
        facultyAndMajor.setLengthFacultyCode(11);
    }

    function testSetLengthFacultyCode_EmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(facultyAndMajor));
        emit MaxLengthFacultyCodeUpdated(5);

        vm.prank(owner);
        facultyAndMajor.setLengthFacultyCode(5);
    }

    /*//////////////////////////////////////////////////////////////
                        SET LENGTH MAJOR CODE
    //////////////////////////////////////////////////////////////*/

    function testSetLengthMajorCode_WhenLengthIsLessThanMinLength() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.InvalidLengthMajorCode.selector, 1));
        facultyAndMajor.setLengthMajorCode(1);
    }

    function testSetLengthMajorCode_WhenLengthIsMoreThanMaxLength() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.InvalidLengthMajorCode.selector, 11));
        facultyAndMajor.setLengthMajorCode(11);
    }

    function testSetLengthMajorCode_EmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(facultyAndMajor));
        emit MaxLengthMajorCodeUpdated(5);

        vm.prank(owner);
        facultyAndMajor.setLengthMajorCode(5);
    }

    /*//////////////////////////////////////////////////////////////
                        SET STUDENTS CONTRACT
    //////////////////////////////////////////////////////////////*/

    function testSetStudentsContract_WhenAddressIsZero() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        facultyAndMajor.setStudentsContract(address(0));
    }

    function testSetStudentsContract_WhenAddressIsSame() public {
        vm.prank(owner);
        facultyAndMajor.setStudentsContract(address(1));

        vm.prank(owner);
        vm.expectRevert("Same address");
        facultyAndMajor.setStudentsContract(address(1));
    }

    function testSetStudentsContract_EmitsEvents() public {
        vm.expectEmit(false, false, false, true, address(facultyAndMajor));
        emit StudentsContractUpdated(address(1));

        vm.prank(owner);
        facultyAndMajor.setStudentsContract(address(1));
    }

    /*//////////////////////////////////////////////////////////////
                        SET UNIVERSITY NAME
    //////////////////////////////////////////////////////////////*/

    function testSetUniversityName_WhenNameIsInvalid() public {
        vm.prank(owner);
        vm.expectRevert("Invalid name");
        facultyAndMajor.setUniversityName("");
    }

    function testSetUniveristyName_WhenNameIsSame() public{
        vm.prank(owner);
        vm.expectRevert("Same name");
        facultyAndMajor.setUniversityName("Nusantara University");
    }

    function testSetUniversityName_EmitsEvent() public {
        vm.expectEmit(false, false, false, true, address(facultyAndMajor));
        emit UniversityNameUpdated("Muhammadiyah University");

        vm.prank(owner);
        facultyAndMajor.setUniversityName("Muhammadiyah University");
    }

    /*//////////////////////////////////////////////////////////////
                        INCREMENT STUDENT COUNT
    //////////////////////////////////////////////////////////////*/
    function testIncrementStudentCount_WhenFacultyNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.incrementStudentCount("", majorName);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.incrementStudentCount("123", majorName);
    }

    function testIncrementStudentCount_WhenMajorNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.incrementStudentCount(facultyName, "");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.incrementStudentCount(facultyName, "123");
    }

    function testIncrementStudentCount_WhenMajorNameOnlyLettersAndSpace() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.incrementStudentCount(facultyName, majorName);

        (, , , uint16 enrolledCountResult, ) = facultyAndMajor.getMajorDetails(facultyName, majorName);
        assertEq(enrolledCountResult, 1);
    }

    function testIncrementStudentCount_WhenFacultyNotFound() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, formattedName));
        facultyAndMajor.incrementStudentCount(facultyName, majorName);
    }

    function testIncrementStudentCount_WhenMajorNotFound() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorNotFound.selector, formattedMajorName));
        facultyAndMajor.incrementStudentCount(facultyName, majorName);
    }

    function testIncrementStudentCount_WhenEnrolledCountIsMoreThanMaxEnrollment() public {
        _addFacultyAndMajor();

        for(uint i = 0; i < maxEnrollment; i++) {
            vm.prank(owner);
            facultyAndMajor.incrementStudentCount(facultyName, majorName);
        }

        (, , , uint16 enrolledCountResult, ) = facultyAndMajor.getMajorDetails(facultyName, majorName);
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MaxEnrollmentReached.selector, majorName, enrolledCountResult, maxEnrollment));
        facultyAndMajor.incrementStudentCount(facultyName, majorName);
    }

    function testIncrementStudentCount_Success() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.incrementStudentCount(facultyName, majorName);

        (, , , uint16 enrolledCountResult, ) = facultyAndMajor.getMajorDetails(facultyName, majorName);
        assertEq(enrolledCountResult, 1);
    }

    /*//////////////////////////////////////////////////////////////
                        DECREMENT STUDENT COUNT
    //////////////////////////////////////////////////////////////*/

    function testDecrementStudentCount_WhenFacultyNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.decrementStudentCount("", majorName);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.decrementStudentCount("123", majorName);
    }

    function testDecrementStudentCount_WhenMajorNameIsInvalid() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(Check.EmptyInput.selector);
        facultyAndMajor.decrementStudentCount(facultyName, "");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "123"));
        facultyAndMajor.decrementStudentCount(facultyName, "123");
    }

    function testDecrementStudentCount_WhenMajorNameOnlyLettersAndSpace() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.incrementStudentCount(facultyName, majorName);

        (, , , uint16 enrolledCountResult, ) = facultyAndMajor.getMajorDetails(facultyName, majorName);
        assertEq(enrolledCountResult, 1);
    }

    function testDecrementStudentCount_WhenFacultyNotFound() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.FacultyNotFound.selector, formattedName));
        facultyAndMajor.decrementStudentCount(facultyName, majorName);
    }

    function testDecrementStudentCount_WhenMajorNotFound() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorNotFound.selector, formattedMajorName));
        facultyAndMajor.decrementStudentCount(facultyName, majorName);
    }

    function testDecrementStudentCount_WhenEnrolledCountIsZero() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.EnrolledCountCannotBeLessThanZero.selector));
        facultyAndMajor.decrementStudentCount(facultyName, majorName);
    }

    function testDecrementStudentCount_Success() public {
        _addFacultyAndMajor();

        vm.prank(owner);
        facultyAndMajor.incrementStudentCount(facultyName, majorName);

        (, , , uint16 enrolledCountResult, ) = facultyAndMajor.getMajorDetails(facultyName, majorName);
        assertEq(enrolledCountResult, 1);
    }
}        