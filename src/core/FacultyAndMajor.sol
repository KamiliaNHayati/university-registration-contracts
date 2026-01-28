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
    address public studentsContract;
    
    /* Private state variables */
    mapping(string => uint8) private facultyIndices;

    /* Errors */
    error FacultyNotFound(string faculty);
    error FacultyAlreadyExists(string faculty);
    error MajorNotFound(string major);
    error MajorAlreadyExists(string major);
    error InvalidLengthMajorCode(uint majorCode);
    error InvalidLengthFacultyCode(uint facultyCode);
    error HasExistingStudents(string student);
    error EnrolledCountCannotBeLessThanZero();
    error MaxEnrollmentReached();

    /* Modifier */
    modifier onlyOwnerOrStudents() {
    if(msg.sender != owner() && msg.sender != studentsContract) {
        revert OwnableUnauthorizedAccount(msg.sender);
    }
    _;
}

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
        string memory formattedName = _formatAndValidateName(facultyName);

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
        string memory formattedName = _formatAndValidateName(facultyName);
        string memory formattedNewName = _formatAndValidateName(newName);

        (bool facultyExist, uint8 facultyIndex) = findFaculty(formattedName);
        if(!facultyExist) revert FacultyNotFound(formattedName);

        Check.validateLengthCode(newFacultyCode, maxLengthFacultyCode);
        Faculty storage faculty = faculties[facultyIndex];

        if (!(Check.compareStrings(formattedName, formattedNewName))){
            faculty.facultyName = formattedNewName;
            delete facultyIndices[formattedName];  // Remove old key
            facultyIndices[formattedNewName] = uint8(facultyIndex) + 1 ;  // Add key
        }

        if (!(Check.compareStrings(faculty.facultyCode, newFacultyCode))){
            faculty.facultyCode = newFacultyCode;
        }
    
        emit UpdateFaculty(faculty.idFaculty, formattedName, faculty.facultyName, faculty.facultyCode);
    }


    function removeFaculty(string calldata facultyName) external override onlyOwner {
        string memory formattedName = _formatAndValidateName(facultyName);
        
        (bool facultyExist, uint8 facultyIndex) = findFaculty(formattedName);
        if(!facultyExist) revert FacultyNotFound(formattedName);

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
        delete facultyIndices[formattedName];
        emit RemoveFaculty(facultyIndex + 1 , formattedName);
    }

    function addMajor(
        string calldata facultyName, 
        string calldata majorName, 
        string calldata majorCode, 
        uint16 maxEnrollment, 
        uint256 enrollmentCost
    ) 
        external 
        override 
        onlyOwner 
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);

        (bool existFaculty, uint8 facultyIndex) = findFaculty(formattedFacultyName);
        if(!existFaculty) revert FacultyNotFound(formattedFacultyName);

        uint8 existingId = faculties[facultyIndex].majors[formattedMajorName].idMajor;
        if(existingId != 0) revert MajorAlreadyExists(formattedMajorName);

        Check.validateLengthCode(majorCode, maxLengthMajorCode);

        Faculty storage faculty = faculties[facultyIndex];
        Major storage major = faculty.majors[formattedMajorName];
        uint8 majorLength = uint8(faculty.majorNames.length) + 1;

        major.idMajor = majorLength;
        major.majorName = formattedMajorName;
        major.majorCode = majorCode;
        major.enrolledCount = 0;
        major.maxEnrollment = maxEnrollment;
        major.enrollmentCost = enrollmentCost;

        faculty.majorNames.push(formattedMajorName);
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
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        string memory formattedNewMajorName = _formatAndValidateName(newMajorName);
        
        Check.validateLengthCode(newMajorCode, maxLengthMajorCode);
        (uint8 facultyIndex, ) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);
        Faculty storage faculty = faculties[facultyIndex];
        
        // Handle rename (if different)
        if (!Check.compareStrings(formattedMajorName, formattedNewMajorName)) {
            _renameMajor(faculty, formattedMajorName, formattedNewMajorName);
        }
        
        // Update the major (whether renamed or not)
        Major storage major = faculty.majors[
            Check.compareStrings(formattedMajorName, formattedNewMajorName) ? formattedMajorName : formattedNewMajorName
        ];
        
        major.majorCode = newMajorCode;
        major.maxEnrollment = newMaxEnrollment;
        major.enrollmentCost = newEnrollmentCost;
        
        emit UpdateMajor(faculty.idFaculty, major.idMajor, formattedMajorName, major.majorName, major.majorCode, major.maxEnrollment, major.enrollmentCost);
    }

    function removeMajor(string calldata facultyName, string calldata majorName) 
        external 
        override 
        onlyOwner 
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        
        (uint8 facultyIndex, uint8 majorIndex) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);        
        Faculty storage faculty = faculties[facultyIndex];
        
        if(faculty.majors[formattedMajorName].enrolledCount > 0) {
            revert HasExistingStudents("Major still has students");
        }
        
        uint8 length = uint8(faculty.majorNames.length);
        
        for (uint8 i = majorIndex; i < length - 1; i++) {
            faculty.majorNames[i] = faculty.majorNames[i + 1];
        }

        faculty.majorNames.pop();
        delete faculty.majors[formattedMajorName];
        emit RemoveMajor(faculty.idFaculty, majorIndex + 1, formattedMajorName);
    }

    function setLengthFacultyCode(uint8 newLength) external override onlyOwner {
        if(newLength < 2 || newLength > 10) {
            revert InvalidLengthFacultyCode(newLength);
        }
        maxLengthFacultyCode = newLength;
        emit MaxLengthFacultyCodeUpdated(newLength);
    }

    function setLengthMajorCode(uint8 newLength) external override onlyOwner {
        if(newLength < 2 || newLength > 10) {
            revert InvalidLengthMajorCode(newLength);
        }
        maxLengthMajorCode = newLength;
        emit MaxLengthMajorCodeUpdated(newLength);
    }

    function setStudentsContract(address _studentsContract) external override onlyOwner {
        studentsContract = _studentsContract;
        emit StudentsContractUpdated(_studentsContract);
    }

    function incrementStudentCount(string calldata facultyName, string calldata majorName) 
        external 
        override
        onlyOwnerOrStudents 
        returns(uint)
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        (uint8 facultyIndex, ) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);
        Major storage major = faculties[facultyIndex].majors[formattedMajorName];
        if(major.enrolledCount >= major.maxEnrollment) {
            revert MaxEnrollmentReached();
        }
        major.enrolledCount += 1;
        return major.enrolledCount;
    }

    function decrementStudentCount(string calldata facultyName, string calldata majorName) 
        external 
        override
        onlyOwnerOrStudents 
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        (uint8 facultyIndex, ) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);
        Major storage major = faculties[facultyIndex].majors[formattedMajorName];
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
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        (bool existFaculty, uint8 facultyIndex) = findFaculty(formattedFacultyName);
        if(!existFaculty) revert FacultyNotFound(formattedFacultyName);

        facultyCode = faculties[facultyIndex].facultyCode;
    }

    function getMajorCode(string calldata facultyName, string calldata majorName) 
        external 
        override 
        view 
        returns (string memory majorCode)
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        (uint8 facultyIndex, ) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);
        majorCode = faculties[facultyIndex].majors[majorName].majorCode;
    }

    function getMajorCost(string calldata facultyName, string calldata majorName) 
        external 
        override 
        view 
        returns (uint)
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        (uint8 facultyIndex, ) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);
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
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        string memory formattedMajorName = _formatAndValidateName(majorName);
        (uint8 facultyIndex, ) = validateFacultyAndMajor(formattedFacultyName, formattedMajorName);
        Major storage major = faculties[facultyIndex].majors[majorName];
        return (major.idMajor, major.majorName, major.majorCode, major.enrolledCount, major.enrollmentCost);
    }

    function listMajors(string calldata facultyName) 
        external 
        override 
        view 
        returns (string[] memory) 
    {
        string memory formattedFacultyName = _formatAndValidateName(facultyName);
        (bool existFaculty, uint8 facultyIndex) = findFaculty(formattedFacultyName);
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

    function _formatAndValidateName(string calldata name) private pure returns (string memory) {
        Check.validateOnlyLettersAndSpaces(name);
        return Check.capitalizeFirstLetters(name);
    }
}        