// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IFacultyAndMajor} from "../../src/interfaces/IFacultyAndMajor.sol";
import {FacultyAndMajorScript} from "../../script/FacultyAndMajor.s.sol";
import {Students} from "../../src/core/Students.sol";
import {StudentsScript} from "../../script/Students.s.sol";
import {Certificate} from "../../src/core/Certificate.sol";
import {CertificateScript} from "../../script/Certificate.s.sol";

contract CertificateTest is Test{

    /*//////////////////////////////////////////////////////////////
                              EVENT
    //////////////////////////////////////////////////////////////*/
    event CertificateMinted(address indexed student, uint256 tokenId);

    /*//////////////////////////////////////////////////////////////
                              STATE
    //////////////////////////////////////////////////////////////*/
    IFacultyAndMajor public facultyAndMajor;
    Students public students;
    Certificate public certificate;
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

        CertificateScript certificateScript = new CertificateScript();
        certificate = certificateScript.run(address(students));

        owner = students.owner();
        applicant = makeAddr("applicant");
        vm.deal(applicant, 10 ether);

        vm.prank(owner);
        facultyAndMajor.setStudentsContract(address(students));
    }

    /*//////////////////////////////////////////////////////////////
                            MINTCERTIFICATE
    //////////////////////////////////////////////////////////////*/
    // helper function
    function _enrollAndGraduateStudent() internal {
        vm.prank(owner);
        facultyAndMajor.addFaculty(facultyName, facultyCode);

        vm.prank(owner);
        facultyAndMajor.addMajor(facultyName, majorName, majorCode, maxEnrollment, cost);

        vm.warp(1750003200);
        students.performUpkeep("");

        vm.prank(applicant);
        students.applyForEnrollment(studentName, facultyName, majorName);

        vm.prank(owner);
        students.updateApplicationStatus(applicant, Students.ApplicationStatus.Approved);

        vm.prank(applicant);
        students.enrollStudent{value: cost}();

        vm.prank(owner);
        students.updateStudentGPA(applicant, 380);

        vm.warp(1851083008);
        vm.prank(applicant);
        (, , , , , uint8 semester, , ) = students.getStudent();
        assertTrue(semester >= 7);

        vm.prank(owner);
        students.graduateStudent(applicant);
    }

    function testMintCertificate_RevertNotGraduated() public {
        vm.prank(applicant);
        vm.expectRevert(Certificate.NotGraduated.selector);
        certificate.mintCertificate();
    }

    function testMintCertificate_RevertAlreadyClaimed() public {
        _enrollAndGraduateStudent();

        vm.prank(applicant);
        certificate.mintCertificate();

        vm.prank(applicant);
        vm.expectRevert(Certificate.AlreadyClaimed.selector);
        certificate.mintCertificate();
    }

    function testMintCertificate_EmitsEvent() public {
        _enrollAndGraduateStudent();

        vm.prank(applicant);
        vm.expectEmit(true, false, false, true, address(certificate));
        emit CertificateMinted(applicant, 0);
        certificate.mintCertificate();
    }
}