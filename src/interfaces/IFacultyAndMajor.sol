// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFacultyAndMajor {
    function addFaculty(string calldata facultyName, string calldata facultyCode) external;
    function updateFaculty(string calldata currentFacultyName, string calldata newFacultyName, string calldata facultyCode) external;
    function removeFaculty(string calldata facultyName) external;

    function addMajor(string calldata facultyName, string calldata majorName, string calldata majorCode, uint16 maxEnrollment, uint enrollmentCost) external;
    function updateMajor(string calldata facultyName, string calldata majorName, string calldata newMajorName, string calldata newMajorCode, uint16 newMaxEnrollment, uint newEnrollmentCost) external;
    function removeMajor(string calldata facultyName, string calldata majorName) external;

    function setLengthFacultyCode(uint8 newLength) external;
    function setLengthMajorCode(uint8 newLength) external;

    function getMajorCost(string calldata facultyName, string calldata majorName) external view returns (uint);
    function getMajorDetails(string calldata facultyName, string calldata majorName) external view returns (uint8, string memory, string memory, uint16, uint);
    function getFacultyCode(string calldata facultyName) external view returns (string memory);
    function getMajorCode(string calldata facultyName, string calldata majorName) external view returns (string memory);
    function incrementStudentCount(string calldata facultyName, string calldata majorName) external returns (uint);
    function decrementStudentCount(string calldata facultyName, string calldata majorName) external;

    function listMajors(string calldata facultyName) external view returns (string[] memory);
    function listFaculties() external view returns (string[] memory);
    
    event NewFaculty(uint indexed facultyId, string facultyName, string facultyCode);
    event UpdateFaculty(uint indexed facultyId, string oldName, string newName, string newFacultyCode);
    event RemoveFaculty(uint indexed facultyId, string facultyName);

    event NewMajor(uint indexed facultyId, uint indexed majorId, string majorName, string majorCode, uint16 maxEnrollment, uint cost);
    event UpdateMajor(uint indexed facultyId, uint indexed majorId, string oldName, string newName, string newMajorCode, uint16 newMaxEnrollment, uint newCost);
    event RemoveMajor(uint indexed facultyId, uint indexed majorId, string majorName);

    event MaxLengthFacultyCodeUpdated(uint32);
    event MaxLengthMajorCodeUpdated(uint32);
}