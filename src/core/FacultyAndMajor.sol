// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Check} from "../libraries/Check.sol";
import {IFacultyAndMajor} from "../interfaces/IFacultyAndMajor.sol";
import {OwnerControlled} from "../access/OwnerControlled.sol";

contract FacultyAndMajor is OwnerControlled, IFacultyAndMajor {

    // ----------------------------
    // Type declarations
    // ----------------------------
    /* Struct */
    struct Major {
        uint8 idMajor; // stable 1-based ID
        string majorName;
        string majorCode;
        uint16 enrolledCount;
        uint16 maxEnrollment;
        uint256 enrollmentCost;
    }

    struct Faculty {
        uint8 idFaculty; // stable 1-based ID
        string facultyName;
        string facultyCode;
        mapping(string => Major) majors;
        string[] majorNames;
    }

    /* Public state variables */
    string public universityName;
    Faculty[] public faculties;
    uint8 public maxLengthFacultyCode;
    uint8 public maxLengthMajorCode;
    
    /* Private state variables */
    mapping(string => uint8) private facultyIndices;

    /* Errors */
    error FacultyNotFound(string faculty);
    error FacultyAlreadyExists(string faculty);
    error MajorNotFound(string major);
    error MajorAlreadyExists(string major);
    error InvalidMajorCode(string majorCode);
    error InvalidLength();
    error InvalidFacultyCode(string facultyCode);
    error HasExistingStudents(string student);
    error EnrolledCountCannotBeLessThanZero();


    /* Functions */
    constructor(
        string memory _universityName, 
        uint8 _maxLengthFacultyCode, 
        uint8 _maxLengthMajorCode
    ) {
        universityName = _universityName;
        maxLengthFacultyCode = _maxLengthFacultyCode;
        maxLengthMajorCode = _maxLengthMajorCode;
    }

    /* External functions */
    function addFaculty(string calldata facultyName, string calldata facultyCode) 
        external 
        override
        onlyOwner 
    {
        Check.validateOnlyLettersAndSpaces(facultyName);

        string memory formattedName = Check.capitalizeFirstLetters(facultyName);

        (bool facultyExist,) = findFaculty(formattedName);
        if(facultyExist) revert FacultyAlreadyExists(formattedName);
        
        Check.validateLengthCode(facultyCode, maxLengthFacultyCode);

        Faculty storage newFaculty = faculties.push();
        uint8 facultyLength = uint8(faculties.length);
        newFaculty.idFaculty = facultyLength;
        newFaculty.facultyName = formattedName;
        newFaculty.facultyCode = facultyCode;
        facultyIndices[formattedName] = newFaculty.idFaculty;

        emit NewFaculty(newFaculty.idFaculty, newFaculty.facultyName, newFaculty.facultyCode);
    }

    function updateFaculty(
        string calldata facultyName, 
        string calldata newName, 
        string calldata newFacultyCode
    ) 
        external
        override
        onlyOwner 
    {
        Check.validateOnlyLettersAndSpaces(facultyName);
        Check.validateOnlyLettersAndSpaces(newName);
        
        (bool facultyExist, uint8 facultyIndex) = findFaculty(facultyName);
        if(!facultyExist) revert FacultyNotFound(facultyName);

        Check.validateLengthCode(newFacultyCode, maxLengthFacultyCode);

        Faculty storage faculty = faculties[facultyIndex];

        if (!(Check.compareStrings(facultyName, newName))){
            faculty.facultyName = newName;
            delete facultyIndices[facultyName];  // Remove old key
            facultyIndices[newName] = uint8(facultyIndex) + 1 ;  // Add key
        }

        if (!(Check.compareStrings(faculty.facultyCode, newFacultyCode))){
            faculty.facultyCode = newFacultyCode;
        }
        emit UpdateFaculty(faculty.idFaculty, facultyName, faculty.facultyName, faculty.facultyCode);
    }


    function removeFaculty(string calldata facultyName) external override onlyOwner {
        Check.validateOnlyLettersAndSpaces(facultyName);
        
        (bool facultyExist, uint8 facultyIndex) = findFaculty(facultyName);
        if(!facultyExist) revert FacultyNotFound(facultyName);

        Faculty storage faculty = faculties[facultyIndex];
        Faculty storage lastFaculty = faculties[faculties.length - 1];
        if(faculty.majorNames.length > 0) revert MajorAlreadyExists("Faculty still has majors");
        
        // If it's not the last item, move the last item to the position of the removed item
        if (facultyIndex < faculties.length - 1) {
            // Copy the last faculty to the position of the faculty being removed
            faculty.idFaculty = lastFaculty.idFaculty;
            faculty.facultyName = lastFaculty.facultyName;
            faculty.facultyCode = lastFaculty.facultyCode;
            
            // Copy major names from the last faculty
            string[] memory tempMajorNames = lastFaculty.majorNames;
            uint8 majorCount = uint8(tempMajorNames.length);
        
            for (uint j = 0; j < majorCount; j++) {
                string memory majorName = tempMajorNames[j];
                faculty.majorNames.push(majorName);
                faculty.majors[majorName] = lastFaculty.majors[majorName];
            }

            // Update the faculty index mapping for the moved faculty
            facultyIndices[faculty.facultyName] = facultyIndex + 1;
        }
        // Remove the last element
        faculties.pop();
        // Remove the faculty from the index mapping
        delete facultyIndices[facultyName];
        emit RemoveFaculty(facultyIndex + 1 , facultyName);
    }

    function addMajor(
        string calldata facultyName, 
        string calldata majorName, 
        string calldata majorCode, 
        uint16 maxEnrollment, 
        uint enrollmentCost
    ) 
        external 
        override 
        onlyOwner 
    {
        Check.validateOnlyLettersAndSpaces(facultyName);
        Check.validateOnlyLettersAndSpaces(majorName);

        (bool existFaculty, uint8 facultyIndex) = findFaculty(facultyName);
        if(!existFaculty) revert FacultyNotFound(facultyName);

        uint8 existingId = faculties[facultyIndex].majors[majorName].idMajor;
        if(existingId != 0) revert MajorAlreadyExists(majorName);

        Check.validateLengthCode(majorCode, maxLengthMajorCode);

        Faculty storage faculty = faculties[facultyIndex];
        Major storage major = faculty.majors[majorName];
        uint8 majorLength = uint8(faculty.majorNames.length) + 1;

        major.idMajor = majorLength;
        major.majorName = majorName;
        major.majorCode = majorCode;
        major.enrolledCount = 0;
        major.maxEnrollment = maxEnrollment;
        major.enrollmentCost = enrollmentCost;

        faculty.majorNames.push(majorName);
        emit NewMajor(faculty.idFaculty, major.idMajor, major.majorName, major.majorCode, major.maxEnrollment, enrollmentCost);
    }

    function updateMajor(
        string calldata facultyName, 
        string calldata majorName, 
        string calldata newMajorName, 
        string calldata newMajorCode, 
        uint16 newMaxEnrollment,
        uint256 newEnrollmentCost
    ) 
        external 
        override 
        onlyOwner 
    {
        Check.validateOnlyLettersAndSpaces(facultyName);
        Check.validateOnlyLettersAndSpaces(newMajorName);
        Check.validateLengthCode(newMajorCode, maxLengthMajorCode);
        
        (uint8 facultyIndex, ) = validateFacultyAndMajor(facultyName, majorName);
        Faculty storage faculty = faculties[facultyIndex];
        
        // Handle rename (if different)
        if (!Check.compareStrings(majorName, newMajorName)) {
            _renameMajor(faculty, majorName, newMajorName);
        }
        
        // Update the major (whether renamed or not)
        Major storage major = faculty.majors[
            Check.compareStrings(majorName, newMajorName) ? majorName : newMajorName
        ];
        major.majorCode = newMajorCode;
        major.maxEnrollment = newMaxEnrollment;
        major.enrollmentCost = newEnrollmentCost;
        
        emit UpdateMajor(faculty.idFaculty, major.idMajor, majorName, major.majorName, major.majorCode, major.maxEnrollment, major.enrollmentCost);
    }

    function removeMajor(string calldata facultyName, string calldata majorName) 
        external 
        override 
        onlyOwner 
    {
        Check.validateOnlyLettersAndSpaces(facultyName);
        Check.validateOnlyLettersAndSpaces(majorName);
        
        (uint8 facultyIndex, uint8 majorIndex) = validateFacultyAndMajor(facultyName, majorName);        
        Faculty storage faculty = faculties[facultyIndex];
        
        if(faculty.majors[majorName].enrolledCount > 0) {
            revert HasExistingStudents("Major still has students");
        }
        
        uint8 length = uint8(faculty.majorNames.length);
        
        for (uint8 i = majorIndex; i < length - 1; i++) {
            faculty.majorNames[i] = faculty.majorNames[i + 1];
        }

        faculty.majorNames.pop();
        delete faculty.majors[majorName];
        emit RemoveMajor(faculty.idFaculty, majorIndex + 1, majorName);
    }

    function setMaxLengthFacultyCode(uint8 newLength) external onlyOwner {
        if(newLength < 2 || newLength > 10) {
            revert InvalidLength();
        }
        maxLengthFacultyCode = newLength;
        emit MaxLengthFacultyCodeUpdated(newLength);
    }

    function setMaxLengthMajorCode(uint8 newLength) external onlyOwner {
        if(newLength < 2 || newLength > 10) {
            revert InvalidLength();
        }
        maxLengthMajorCode = newLength;
        emit MaxLengthMajorCodeUpdated(newLength);
    }

    function incrementStudentCount(string calldata facultyName, string calldata majorName) 
        external 
        override
        onlyOwner 
        returns(uint)
    {
        (uint8 facultyIndex, ) = validateFacultyAndMajor(facultyName, majorName);
        Major storage major = faculties[facultyIndex].majors[majorName];
        major.enrolledCount += 1;
        return major.enrolledCount;
    }

    function decrementStudentCount(string calldata facultyName, string calldata majorName) 
        external 
        override
        onlyOwner 
    {
        (uint8 facultyIndex, ) = validateFacultyAndMajor(facultyName, majorName);
        Major storage major = faculties[facultyIndex].majors[majorName];
        if (major.enrolledCount == 0) {
            revert EnrolledCountCannotBeLessThanZero();
        }
        major.enrolledCount -= 1;
    }

    /* External functions that are view */
    function getFacultyCode(string calldata facultyName) 
        external 
        override 
        view 
        returns (string memory facultyCode)
    {
        (bool existFaculty, uint8 facultyIndex) = findFaculty(facultyName);
        if(!existFaculty) revert FacultyNotFound(facultyName);

        facultyCode = faculties[facultyIndex].facultyCode;
    }

    function getMajorCode(string calldata facultyName, string calldata majorName) 
        external 
        override 
        view 
        returns (string memory majorCode)
    {
        (uint8 facultyIndex, ) = validateFacultyAndMajor(facultyName, majorName);
        majorCode = faculties[facultyIndex].majors[majorName].majorCode;
    }

    function getMajorCost(string calldata facultyName, string calldata majorName) 
        external 
        override 
        view 
        returns (uint)
    {
        (uint8 facultyIndex, ) = validateFacultyAndMajor(facultyName, majorName);
        Faculty storage faculty = faculties[facultyIndex];
        uint enrollmentCost = faculty.majors[majorName].enrollmentCost;        
        return enrollmentCost;
    }
    
    function getMajorDetails(string calldata facultyName, string calldata majorName) 
        external 
        override 
        view 
        returns (uint8, string memory, string memory, uint16, uint)
    {
        (uint8 facultyIndex, ) = validateFacultyAndMajor(facultyName, majorName);
        Major storage major = faculties[facultyIndex].majors[majorName];
        return (major.idMajor, major.majorName, major.majorCode, major.enrolledCount, major.enrollmentCost);
    }

    function listMajors(string calldata facultyName) 
        external 
        override 
        view 
        returns (string[] memory) 
    {
        (bool existFaculty, uint8 facultyIndex) = findFaculty(facultyName);
        if(!existFaculty) revert FacultyNotFound("Faculty not found");
        return faculties[facultyIndex].majorNames;
    }
    
    function listFaculties() external override view returns (string[] memory){
        string[] memory getFacultyName = new string[](faculties.length);
        uint8 length = uint8(faculties.length);
        for(uint8 i = 0; i < length; i++){
            getFacultyName[i] = faculties[i].facultyName;
        }
        return getFacultyName;
    }
    
    /* Private functions */
    // Internal helper to reduce stack depth
    function _renameMajor(Faculty storage faculty, string memory oldName, string memory newName) private {
        Major storage oldMajor = faculty.majors[oldName];
        Major storage newMajor = faculty.majors[newName];
        
        newMajor.idMajor = oldMajor.idMajor;
        newMajor.majorName = newName;
        newMajor.majorCode = oldMajor.majorCode;
        newMajor.enrolledCount = oldMajor.enrolledCount;
        newMajor.maxEnrollment = oldMajor.maxEnrollment;
        newMajor.enrollmentCost = oldMajor.enrollmentCost;
        
        delete faculty.majors[oldName];
    }

    function findFaculty(string memory facultyName) 
        private 
        view 
        returns (bool, uint8) 
    {
        uint8 index = facultyIndices[facultyName];
        // Return true if faculty exists (index > 0), false otherwise
        return (index != 0, index > 0 ? index - 1 : 0);
    }

    function validateFacultyAndMajor(string memory facultyName, string memory majorName) 
        private 
        view 
        returns(uint8, uint8)
    {
        (bool existFaculty, uint8 facultyIndex) = findFaculty(facultyName);
        if(!existFaculty) revert FacultyNotFound(facultyName);
        
        uint8 idMajor = faculties[facultyIndex].majors[majorName].idMajor;
        if(idMajor == 0) revert MajorNotFound(majorName);
        
        return (facultyIndex, idMajor - 1);
    }
}        