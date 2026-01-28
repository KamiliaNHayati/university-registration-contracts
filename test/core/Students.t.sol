// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {FacultyAndMajorScript} from "../../script/FacultyAndMajor.s.sol";
import {Students} from "../../src/core/Students.sol";
import {StudentsScript} from "../../script/Students.s.sol";
import {OwnerControlled} from "../../src/access/OwnerControlled.sol";
import {Check} from "../../src/libraries/Check.sol";
import {Email} from "../../src/libraries/Email.sol";

contract StudentsTest is Test{

    /*//////////////////////////////////////////////////////////////
                              EVENT
    //////////////////////////////////////////////////////////////*/
    event StudentEnrolled(string studentId, string faculty, string major, Students.StudentStatus status);
    event StudentDroppedOut(string studentId, string faculty, string major);
    event SemesterUpdated(uint8 indexed semester);
    event ApplicationSubmitted(address applicant);
    event ApplicationApproved(address applicant);
    event ApplicationRejected(address applicant);
    event ValidityPeriodUpdated(uint8 month, uint8 day, uint8 yearOffset);

    /*//////////////////////////////////////////////////////////////
                              STATE
    //////////////////////////////////////////////////////////////*/
    Students public students;
    IFacultyAndMajor public facultyAndMajor;
    address public owner;
    address applicant;
    string facultyName = "School of Computing";
    string facultyCode = "1200";
    string majorName = "Information Technology";
    string majorCode = "1201";
    uint16 maxEnrollment = 110;
    uint cost = 0.8 ether;
    string studentName = "Rizky";

    function setUp() public {
        FacultyAndMajorScript facultyAndMajorScript = new FacultyAndMajorScript();
        facultyAndMajor = facultyAndMajorScript.run("Nusantara University", 4, 4);

        StudentsScript studentsScript = new StudentsScript();
        students = studentsScript.run(address(facultyAndMajor), 6, 8, 5, 20, 4);

        owner = students.owner();
        applicant = makeAddr("applicant");
        vm.deal(applicant, 10 ether);

        vm.prank(owner);
        facultyAndMajor.setStudentsContract(address(students));
    }

    /*//////////////////////////////////////////////////////////////
                              PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/
    function testPerformUpKeep_WithinEnrollmentMonths() public {
        vm.warp(1750003200);
        students.performUpkeep("");
        assertEq(students.isOpen(), true);
    }

    function testPerformUpKeep_NotInEnrollmentMonths() public {
        vm.warp(1750003200);
        students.performUpkeep("");

        vm.warp(1741510139);
        students.performUpkeep("");
        assertEq(students.isOpen(), false);
    }

    function testPerformUpKeep_RevertsWhenCheckUpKeepIsFalse() public {
        vm.warp(1741510139);
        vm.expectRevert(
            abi.encodeWithSelector(Students.UpkeepNotNeeded.selector)
        );
        students.performUpkeep("");
    }

    /*//////////////////////////////////////////////////////////////
                            APPLYFORENROLLMENT
    //////////////////////////////////////////////////////////////*/

    function testApplyForEnrollment_WhenOwnerAttemptsToApply() public {
        vm.prank(owner);
        vm.expectRevert(Students.NonOnlyOwner.selector);
        students.applyForEnrollment(studentName, facultyName, majorName);
    }

    function testApplyForEnrollment_RevertsWhenEnrollmentClosed() public {
        vm.warp(1741510139);
        vm.prank(applicant);
        vm.expectRevert(Students.EnrollmentClosed.selector);
        students.applyForEnrollment(studentName, facultyName, majorName);
    }

    function testApplyForEnrollment_WhereStudentNameIsInvalid() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        vm.expectRevert(Check.EmptyInput.selector);
        students.applyForEnrollment("", facultyName, majorName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "Rizky123"));
        students.applyForEnrollment("Rizky123", facultyName, majorName);
    }

    function testApplyForEnrollment_WhereFacultyNameIsInvalid() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        vm.expectRevert(Check.EmptyInput.selector);
        students.applyForEnrollment(studentName, "", majorName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "Faculty123"));
        students.applyForEnrollment(studentName, "Faculty123", majorName);
    }

    function testApplyForEnrollment_WhereMajorNameIsInvalid() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        vm.expectRevert(Check.EmptyInput.selector);
        students.applyForEnrollment(studentName, facultyName, "");

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "Major123"));
        students.applyForEnrollment(studentName, facultyName, "Major123");
    }

    function testApplyForEnrollment_EmitsEvent() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.expectEmit(false, false, false, true, address(students));
        emit ApplicationSubmitted(address(applicant));

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        (, , , , Students.ApplicationStatus status) = students.applications(applicant);
        assert(status == Students.ApplicationStatus.Pending);
    }

    /*//////////////////////////////////////////////////////////////
                            UPDATEAPPLICATIONSTATUS
    //////////////////////////////////////////////////////////////*/
    function testUpdateApplicationStatus_StatusApproved() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.expectEmit(false, false, false, true, address(students));
        emit ApplicationApproved(address(applicant));

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        (, , , , Students.ApplicationStatus status) = students.applications(applicant);
        assert(status == Students.ApplicationStatus.Approved);

        address[] memory pendingApplicants = students.getPendingApplicants();
        assertEq(pendingApplicants.length, 0);
    }

    function testUpdateApplicationStatus_StatusRejected() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.expectEmit(false, false, false, true, address(students));
        emit ApplicationRejected(address(applicant));

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Rejected);

        (, , , , Students.ApplicationStatus status) = students.applications(applicant);
        assert(status == Students.ApplicationStatus.Rejected);
    }

    /*//////////////////////////////////////////////////////////////
                            ENROLLSTUDENT
    //////////////////////////////////////////////////////////////*/
    function testEnrollStudent_RevertsWhenApplicationNotApproved() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(applicant);
        vm.expectRevert(Students.NotApproved.selector);
        students.enrollStudent();
    }

    function testEnrollStudent_RevertsWhenNotEnrolledInTime() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.warp(1795490000);
        students.performUpkeep("");

        vm.prank(applicant);
        vm.expectRevert(Students.InvalidEnrollmentPeriod.selector);
        students.enrollStudent{value: cost}();
    }

    function testEnrollStudent_RevertsWhenAlreadyEnrolled() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.AlreadyEnrolled.selector, applicant));
        students.enrollStudent{value: cost}();
    }

    function testEnrollStudent_RevertsWhenNotSendWithTheSameAmount() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.InvalidPaymentAmount.selector, cost - 0.2 ether, cost));
        students.enrollStudent{value: cost - 0.2 ether}();
    }

    function testEnrollStudent_StudentEnrolledWith10Students() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        for(uint i = 1; i <= 10; i++) {
            address student = address(uint160(i));
            hoax(student, 1 ether);
            students.applyForEnrollment(studentName, facultyName, majorName);

            vm.prank(owner);
            students.updateApplicationStatus(student, Students.ApplicationStatus.Approved);

            vm.prank(student);
            students.enrollStudent{value: cost}();  
        }
    }

    function testEnrollStudent_StudentEnrolledWith100Students() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        for(uint i = 1; i <= maxEnrollment; i++) {
            address student = address(uint160(i));
            hoax(student, 1 ether);
            students.applyForEnrollment(studentName, facultyName, majorName);

            vm.prank(owner);
            students.updateApplicationStatus(student, Students.ApplicationStatus.Approved);

            vm.prank(student);
            students.enrollStudent{value: cost}();  
        }
    }    

    function testEnrollStudent_WithDifferentValidityMonths() public{
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        for(uint8 i = 1; i <= 12; i++) {
            vm.prank(owner);
            students.setValidityPeriod(i, 1, 1);

            address student = address(uint160(i));
            hoax(student, 1 ether);
            students.applyForEnrollment(studentName, facultyName, majorName);

            vm.prank(owner);
            students.updateApplicationStatus(student, Students.ApplicationStatus.Approved);

            vm.prank(student);
            students.enrollStudent{value: cost}();

            // assert(students.validityEndMonth() == i);
            assertEq(students.validityEndMonth(), i);
        }
    }

    function testEnrollStudent_EmitsEvents() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        string memory id = string.concat(facultyCode, majorCode, "001");
        vm.expectEmit(false, false, false, true, address(students));
        emit StudentEnrolled(id, facultyName, majorName, Students.StudentStatus.Active);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();
    }

    /*//////////////////////////////////////////////////////////////
                            PROCESSSTUDENTDROP
    //////////////////////////////////////////////////////////////*/
    function testProcessStudentDropout_WhenStudentHasNotEnrolled() public {
        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.StudentNotEnrolled.selector, applicant));
        students.processStudentDropout(studentName);
    }

    function testProcessStudentDropout_WhenStudentNameIsNotMatch() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.StudentNameMismatch.selector, "Rizky Santoso", studentName));
        students.processStudentDropout("Rizky Santoso");
    }

    function testProcessStudentDropOut_WhenStudentHasDroppedOut() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        students.processStudentDropout(studentName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.StudentAlreadyDroppedOut.selector, applicant));
        students.processStudentDropout(studentName);
    }

    function testProcessStudentDropout_EmitsEvents() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        string memory id = string.concat(facultyCode, majorCode, "001");
        vm.expectEmit(false, false, false, true, address(students));
        emit StudentDroppedOut(id, facultyName, majorName);

        vm.prank(applicant);
        students.processStudentDropout(studentName);
    }

    /*//////////////////////////////////////////////////////////////
                            SETVALIDITYPERIOD
    //////////////////////////////////////////////////////////////*/

    function testSetValidityPeriod_RevertsWhenInvalidMonth() public {
        vm.prank(owner);
        vm.expectRevert("Invalid month");
        students.setValidityPeriod(13, 1, 1);
    }

    function testSetValidityPeriod_RevertsWhenInvalidDay() public {
        vm.prank(owner);
        vm.expectRevert("Invalid day");
        students.setValidityPeriod(1, 32, 1);
    }

    function testSetValidityPeriod_RevertsWhenInvalidYearOffset() public {
        vm.prank(owner);
        vm.expectRevert("Invalid year offset");
        students.setValidityPeriod(1, 1, 11);
    }

    function testSetValidityPeriod_EmitsEvents() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true, address(students));
        emit ValidityPeriodUpdated(12, 31, 4);
        students.setValidityPeriod(12, 31, 4);
    }


    /*//////////////////////////////////////////////////////////////
                                GETTER TESTS
    //////////////////////////////////////////////////////////////*/
    function testGetStudent() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        (, string memory studentNameResult, , , , , , ) = students.getStudent();

        assertEq(studentNameResult, studentName);
    }

    function testCheckUpkeep() public {
        vm.warp(1750003200);
        (bool upkeepNeeded, ) = students.checkUpkeep("");
        assertEq(upkeepNeeded, true);

        vm.warp(1750003200 + 90 days);
        (upkeepNeeded, ) = students.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testGetPendingApplicants() public{
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        address[] memory pendingApplicants = students.getPendingApplicants();
        assertEq(pendingApplicants.length, 1);
    }

    function testListEnrolledStudents() public {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(address(applicant), Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        address[] memory enrolledStudents = students.listEnrolledStudents();
        assertEq(enrolledStudents.length, 1);
    }
    

    /*//////////////////////////////////////////////////////////////
                            OWNER CONTRACT
    //////////////////////////////////////////////////////////////*/

    function testWithdraw_OnlyOwner() public {
        // Send some ETH to contract first
        vm.deal(address(students), 1 ether);
        
        // Non-owner tries to withdraw
        vm.prank(applicant);
        vm.expectRevert(); // Ownable error
        students.withdraw(payable(applicant), 1 ether);
    }

    function testWithdraw_Success() public {
        vm.deal(address(students), 1 ether);
        uint256 balanceBefore = owner.balance;
        
        vm.prank(owner);
        students.withdraw(payable(owner), 1 ether);
    
        assertEq(owner.balance, balanceBefore + 1 ether);
    }

    function testWithdraw_FailedToSend() public {
        // Deploy rejecting contract
        RejectingContract rejector = new RejectingContract();
        
        // Fund the Students contract
        vm.deal(address(students), 1 ether);
        
        // Try to withdraw to rejecting contract
        vm.prank(owner);
        vm.expectRevert(OwnerControlled.FailedToSend.selector);
        students.withdraw(payable(address(rejector)), 1 ether);
    }

    function testReceive_Reverts() public {
        vm.deal(applicant, 1 ether);
        vm.prank(applicant);
        vm.expectRevert();
        address(students).call{value: 1 ether}("");
    }

    function testGetBalance() public {
        assertEq(students.getBalance(), 0);
    }

    function testDirectlySendETHWithoutSendData() public {
        vm.deal(applicant, 1 ether);
        vm.prank(applicant);
        (bool success,) = address(students).call{value: 1 ether}("");
        assertEq(success, false);
    }

    function testDirectlySendETHWithSendData() public {
        vm.deal(applicant, 1 ether);
        vm.prank(applicant);
        (bool success,) = address(students).call{value: 1 ether}("0x1234567890123456789012345678901234567890");
        assertEq(success, false);
    }

}

// Contract that refuses to receive ETH
contract RejectingContract {
    receive() external payable {
        revert("I reject ETH");
    }
}