// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajor} from "../../src/core/FacultyAndMajor.sol";
import {FacultyAndMajorScript} from "../../script/FacultyAndMajor.s.sol";
import {Students} from "../../src/core/Students.sol";
import {StudentsScript} from "../../script/Students.s.sol";
import {OwnerControlled} from "../../src/access/OwnerControlled.sol";
import {Check} from "../../src/libraries/Check.sol";

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
    event StudentGPAUpdated(address indexed student, uint16 gpa);
    event StudentGraduated(address indexed student, string studentId);
    event EnrollmentMonthsUpdated(uint8 minimumMonth, uint8 maximumMonth);
    event FacultyAndMajorUpdated(address indexed facultyAndMajor);

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
        students = studentsScript.run(address(facultyAndMajor), 6, 8, 5, 20, 4, 3);

        owner = students.owner();
        applicant = makeAddr("applicant");
        vm.deal(applicant, 10 ether);

        vm.prank(owner);
        facultyAndMajor.setStudentsContract(address(students));
    }

    /*//////////////////////////////////////////////////////////////
                              HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/
    function _setupAndOpenEnrollment() internal {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);
        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");
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

    function testApplyForEnrollment_WhereMajorDoesNotExist() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(FacultyAndMajor.MajorNotFound.selector, "Non Existent Major"));
        students.applyForEnrollment(studentName, facultyName, "Non Existent Major");
    }

    function testApplyForEnrollment_WhereStudentsApplyMoreThanMaximumApply() public{
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, "Artificial Intelligence", "1202", maxEnrollment, cost);
        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, "Artificial Intelligence");

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, "Computer Science", "1203", maxEnrollment, cost);
        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, "Computer Science");

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, "Data Science", "1205", maxEnrollment, cost);
        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.MaxApplicationsExceeded.selector, 3, 3));
        students.applyForEnrollment(studentName, facultyName, "Data Science");
    }

    function testApplyForEnrollment_WhereStudentAlreadyApplied() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.AlreadyApplied.selector, majorName));
        students.applyForEnrollment(studentName, facultyName, majorName);
    }

    function testApplyForEnrollment_WhereStudentNameIsInvalid() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        vm.expectRevert(Check.EmptyInput.selector);
        students.applyForEnrollment("", facultyName, majorName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "Rizky123"));
        students.applyForEnrollment("Rizky123", facultyName, majorName);
    }

    function testApplyForEnrollment_WhereFacultyNameIsInvalid() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        vm.expectRevert(Check.EmptyInput.selector);
        students.applyForEnrollment(studentName, "", majorName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "Faculty123"));
        students.applyForEnrollment(studentName, "Faculty123", majorName);
    }

    function testApplyForEnrollment_WhereMajorNameIsInvalid() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        vm.expectRevert(Check.EmptyInput.selector);
        students.applyForEnrollment(studentName, facultyName, "");

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Check.OnlyLettersAndSpaces.selector, "Major123"));
        students.applyForEnrollment(studentName, facultyName, "Major123");
    }

    function testApplyForEnrollment_EmitsEvent() public {
        _setupAndOpenEnrollment();

        vm.expectEmit(false, false, false, true, address(students));
        emit ApplicationSubmitted(applicant);

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        (, , , , Students.ApplicationStatus status) = students.applications(applicant, 0);
        assert(status == Students.ApplicationStatus.Pending);
    }

    /*//////////////////////////////////////////////////////////////
                            UPDATEAPPLICATIONSTATUS
    //////////////////////////////////////////////////////////////*/

    function testUpdateApplicationStatus_WhereApplicationAlreadyBeenApproved() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Students.AlreadyApproved.selector, applicant, majorName));
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);
    }

    function testUpdateApplicationStatus_StatusApproved() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.expectEmit(false, false, false, true, address(students));
        emit ApplicationApproved(applicant);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        (, , , , Students.ApplicationStatus status) = students.applications(applicant, 0);
        assert(status == Students.ApplicationStatus.Approved);

        address[] memory pendingApplicants = students.getPendingApplicants();
        assertEq(pendingApplicants.length, 0);
    }

    function testUpdateApplicationStatus_StatusRejected() public {
       _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.expectEmit(false, false, false, true, address(students));
        emit ApplicationRejected(applicant);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Rejected);

        (, , , , Students.ApplicationStatus status) = students.applications(applicant, 0);
        assert(status == Students.ApplicationStatus.Rejected);
    }

    /*//////////////////////////////////////////////////////////////
                            ENROLLSTUDENT
    //////////////////////////////////////////////////////////////*/
    function testEnrollStudent_WhereApplicationNotApproved() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(applicant);
        vm.expectRevert(Students.NotApproved.selector);
        students.enrollStudent();
    }

    function testEnrollStudent_RevertsWhenNotEnrolledInTime() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.warp(1795490000);
        students.performUpkeep("");

        vm.prank(applicant);
        vm.expectRevert(Students.InvalidEnrollmentPeriod.selector);
        students.enrollStudent{value: cost}();
    }

    function testEnrollStudent_RevertsWhenAlreadyEnrolled() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.AlreadyEnrolled.selector, applicant));
        students.enrollStudent{value: cost}();
    }

    function testEnrollStudent_RevertsWhenNotSendWithTheSameAmount() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.InvalidPaymentAmount.selector, cost - 0.2 ether, cost));
        students.enrollStudent{value: cost - 0.2 ether}();
    }

    function testEnrollStudent_StudentEnrolles10Students() public {
        _setupAndOpenEnrollment();

        for(uint i = 1; i <= 10; i++) {
            address student = address(uint160(i));
            hoax(student, 1 ether);
            students.applyForEnrollment(studentName, facultyName, majorName);

            vm.prank(owner);
            students.updateApplicationStatus(student, majorName, Students.ApplicationStatus.Approved);

            vm.prank(student);
            students.enrollStudent{value: cost}();  
        }
    }

    function testEnrollStudent_StudentEnrolles100Students() public {
        _setupAndOpenEnrollment();

        for(uint i = 1; i <= maxEnrollment; i++) {
            address student = address(uint160(i));
            hoax(student, 1 ether);
            students.applyForEnrollment(studentName, facultyName, majorName);

            vm.prank(owner);
            students.updateApplicationStatus(student, majorName, Students.ApplicationStatus.Approved);

            vm.prank(student);
            students.enrollStudent{value: cost}();  
        }
    }    

    function testEnrollStudent_WithDifferentValidityMonths() public{
        _setupAndOpenEnrollment();

        for(uint8 i = 1; i <= 12; i++) {
            vm.prank(owner);
            students.setValidityPeriod(i, 1, 1);

            address student = address(uint160(i));
            hoax(student, 1 ether);
            students.applyForEnrollment(studentName, facultyName, majorName);

            vm.prank(owner);
            students.updateApplicationStatus(student, majorName, Students.ApplicationStatus.Approved);

            vm.prank(student);
            students.enrollStudent{value: cost}();

            // assert(students.validityEndMonth() == i);
            assertEq(students.validityEndMonth(), i);
        }
    }

    function testEnrollStudent_EmitsEvents() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

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
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.StudentNameMismatch.selector, "Rizky Santoso", studentName));
        students.processStudentDropout("Rizky Santoso");
    }

    function testProcessStudentDropout_WhenStudentHasDroppedOut() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(applicant);
        students.processStudentDropout(studentName);

        vm.prank(applicant);
        vm.expectRevert(abi.encodeWithSelector(Students.StudentAlreadyDroppedOut.selector, applicant));
        students.processStudentDropout(studentName);
    }

    function testProcessStudentDropout_EmitsEvents() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

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
                        SETENROLLMENTMONTHS
    //////////////////////////////////////////////////////////////*/
    function testSetEnrollmentMonths_InvalidMinimumMonth() public {
        vm.prank(owner);
        vm.expectRevert("Invalid minimum month");
        students.setEnrollmentMonths(0, 11);
    }

    function testSetEnrollmentMonths_InvalidMaximumMonth() public {
        vm.prank(owner);
        vm.expectRevert("Invalid maximum month");
        students.setEnrollmentMonths(1, 13);
    }

    function testSetEnrollmentMonths_WhenMinimumMoreThanMaximumMonth() public {
        vm.prank(owner);
        vm.expectRevert("Min must be <= max");
        students.setEnrollmentMonths(12, 1);
    }

    function testSetEnrollmentMonths_EmitsEvents() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true, address(students));
        emit EnrollmentMonthsUpdated(1, 11);
        students.setEnrollmentMonths(1, 11);
    }

    /*//////////////////////////////////////////////////////////////
                            SETFACULTYANDMAJOR
    //////////////////////////////////////////////////////////////*/
    function testSetFacultyAndMajor_RevertWhenZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        students.setFacultyAndMajor(address(0));
    }

    function testSetFacultyAndMajor_EmitsEvents() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true, address(students));
        emit FacultyAndMajorUpdated(address(1));
        students.setFacultyAndMajor(address(1));
    }

    /*//////////////////////////////////////////////////////////////
                            UPDATESTUDENTGPA
    //////////////////////////////////////////////////////////////*/

    function testUpdateStudentGPA_RevertsInvalidGPA() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Students.InvalidGPA.selector, 450));
        students.updateStudentGPA(applicant, 450);
    }

    function testUpdateStudentGPA_EmitsEvents() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(students));
        emit StudentGPAUpdated(applicant, 200);
        students.updateStudentGPA(applicant, 200);
    }

    /*//////////////////////////////////////////////////////////////
                            GRADUATESTUDENT
    //////////////////////////////////////////////////////////////*/

    function testGraduateStudent_RevertsWhenNotEligible() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Students.NotEligibleForGraduation.selector, applicant, 1));
        students.graduateStudent(applicant);
    }

    function testGraduateStudent_RevertsWhenGPATooLow() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        students.updateStudentGPA(applicant, 180);

        vm.warp(1851083008);
        vm.prank(applicant);
        (, , , , , uint8 semester, , ) = students.getStudent();
        assertTrue(semester >= 7);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Students.GPATooLow.selector, 180));
        students.graduateStudent(applicant);
    }

    function testGraduateStudent_EmitsEvents() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        students.updateStudentGPA(applicant, 380);

        vm.warp(1851083008);
        vm.prank(applicant);
        (, , , , , uint8 semester, , ) = students.getStudent();
        assertTrue(semester >= 7);

        string memory id = string.concat(facultyCode, majorCode, "001");
        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(students));
        emit StudentGraduated(applicant, id);
        students.graduateStudent(applicant);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTER TESTS
    //////////////////////////////////////////////////////////////*/
    function testGetStudent() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

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
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        address[] memory pendingApplicants = students.getPendingApplicants();
        assertEq(pendingApplicants.length, 1);
    }

    function testHasGraduated() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        students.updateStudentGPA(applicant, 380);

        vm.warp(1851083008);
        vm.prank(applicant);
        (, , , , , uint8 semester, , ) = students.getStudent();
        assertEq(semester, 7);

        vm.prank(owner);
        students.graduateStudent(applicant);

        vm.prank(owner);
        assertEq(students.hasGraduated(applicant), true);
    }

    function testGetGPA() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        students.updateStudentGPA(applicant, 380);

        vm.prank(owner);
        assertEq(students.getGPA(applicant), 380);
    }

    function testListEnrolledStudents() public {
        _setupAndOpenEnrollment();

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, majorName, Students.ApplicationStatus.Approved);

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
        (bool success, ) = address(students).call{value: 1 ether}("");
        success; // Silence unused variable warning
    }

    function testGetBalance() public view {
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