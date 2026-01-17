// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFacultyAndMajor} from "../interfaces/IFacultyAndMajor.sol";
import {Email} from "../libraries/Email.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Check} from "../libraries/Check.sol";
import {CheckWrapper} from "../wrappers/CheckWrapper.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {IStudents} from "../interfaces/IStudents.sol";

contract Students is IStudents{

    IFacultyAndMajor private facultyAndMajor;
    CheckWrapper private checkWrapper;

    constructor(address _facultyAndMajor) {
        facultyAndMajor = IFacultyAndMajor(_facultyAndMajor);
        checkWrapper = new CheckWrapper();
    }
    
    struct Biodata {
        uint studentId;
        string name;
        string nim;
        string email;
        string semester;
        string major;
        string faculty;
        string validityPeriod;
        string status;
        bool hasEnrolled;
    }
    mapping(address => Biodata) private bio;
    uint16 studentCount;
    uint16 year = 2024;

    error AlreadyEnrolled(address student);
    error StudentAlreadyDroppedOut(address student);
    error EnrollmentClosed(uint8 currentMonth);
    error InvalidPaymentAmount(uint256 sent, uint256 required);
    error MajorOperationFailed(string faculty, string major, string reason);
    error StudentNotEnrolled(address student);
    error StudentNameMismatch(string provided, string stored);
    error InvalidEnrollmentPeriod(uint8 currentMonth, uint16 currentYear, uint16 storedYear, string reason);
    error NimGenerationFailed(string faculty, string major, string reason);
    error StudentCountError(string faculty, string major, string reason);


    function getNextStudentNumber(string memory faculty_input, string memory major_input) private returns(string memory) {
        try facultyAndMajor.incrementStudentCount(faculty_input, major_input) returns (uint _lastNim) {
            if (_lastNim == 0) {
                revert StudentCountError(faculty_input, major_input, "Student count is zero");
            }
            
            string memory nimLastDigits;
            if (_lastNim >= 1 && _lastNim < 10) {
                nimLastDigits = string.concat("00", Strings.toString(_lastNim));
            }
            else if(_lastNim >= 10 && _lastNim < 100) {
                nimLastDigits = string.concat("0", Strings.toString(_lastNim));
            }
            return nimLastDigits;
        } catch (bytes memory /*lowLevelData*/) {
            revert NimGenerationFailed(
                faculty_input, 
                major_input, 
                "Failed to increment student count"
            );
        }
    }    

    function generateStudentId(string memory faculty_input, string memory major_input) private returns (string memory) {
        string memory nimMiddle = facultyAndMajor.getMajorMiddleNum(faculty_input, major_input);        
        uint year_created = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);
        string memory _lastNim = getNextStudentNumber(faculty_input, major_input);(faculty_input, major_input);
        return string.concat(Strings.toString(year_created), nimMiddle, _lastNim);
      } 

    function generateStudentEmail(string memory studentName, string memory studentsFaculty) private view returns(string memory) {
        string memory nameCopy = string(bytes(studentName));
        string memory changeResult = Email.convertSpacesToDots(nameCopy);
        uint yearCreated = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp) % 100; // Inlined getShortYear logic
        string memory abbreviationResult = facultyAndMajor.getAbbreviation(studentsFaculty);
        return string.concat(changeResult, abbreviationResult, Strings.toString(yearCreated), "@mail.universitas.ac.id");
    }
    
    function calculateValidityPeriod() private view returns(string memory expiredYear){
        uint timeCreated = block.timestamp;
        uint expiredDate_year = BokkyPooBahsDateTimeLibrary.getYear(timeCreated) + 4;
        expiredYear = string.concat("Berlaku s/d tnggal 31 Juli ", Strings.toString(expiredDate_year));
        return expiredYear;
    }

    function getMajorCost(string memory faculty, string memory major) external view returns(uint) {
        try facultyAndMajor.getMajorCost(faculty, major) returns (uint cost) {
            return cost; 
        } catch (bytes memory /*lowLevelData*/) {
            // A single catch clause for all types of errors
            revert MajorOperationFailed(faculty, major, "Error retrieving major cost");
        }  
    }

    function validateEnrollmentFee(uint value, string memory _faculty, string memory _major) private view {
        try facultyAndMajor.getMajorCost(_faculty, _major) returns (uint cost) {
            if(value != cost) {
                revert InvalidPaymentAmount(value, cost);
            }
        } catch (bytes memory /*lowLevelData*/) {
            // A single catch clause for all types of errors
            revert MajorOperationFailed(_faculty, _major, "Error retrieving major cost");
        }    
    }

    // Combined time check function
    function isValidEnrollmentPeriod(uint timestamp) private returns (bool) {
        (uint256 currentYear, uint256 month, uint256 day, 
        uint256 hour, uint256 minute, uint256 second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        
        // Check enrollment month (August-September)
        uint8 currentMonth = uint8(month);
        if (!(currentMonth <= 8 || currentMonth > 9)) {
            revert InvalidEnrollmentPeriod(
                currentMonth,
                uint16(currentYear),
                year,
                "Outside enrollment months (August-September)"
            );
        }

        // Check year transition (January 1st at 00:00:01)
        if (year < currentYear && 
            month == 1 && 
            day == 1 && 
            hour == 0 && 
            minute == 0 && 
            second == 1) {
            year = uint16(currentYear);
            return true; // Year changed
        }

        return false; // No year change
    }

    function enrollStudent(uint value, address studentAddress, string memory _name, string memory _faculty, string memory _major) external {
        Biodata storage senderData = bio[studentAddress];

        if(senderData.hasEnrolled) revert AlreadyEnrolled(studentAddress);
        validateEnrollmentFee(value, _faculty, _major);

        string memory name = checkWrapper.checkCapitalLetters(_name);
        string memory nim = generateStudentId(_faculty, _major);
        string memory email = generateStudentEmail(_name, _faculty);
        string memory validityPeriod = calculateValidityPeriod();

        if(isValidEnrollmentPeriod(block.timestamp)) {
            studentCount = 0;
        }

        senderData.hasEnrolled = true;
        uint16 enrolledStudents = ++studentCount;
        bio[studentAddress] = Biodata(enrolledStudents, name, nim, email, "semester 1", _major, _faculty, validityPeriod, "Aktif", true);
        emit AddStudent(enrolledStudents, _faculty, _major, validityPeriod, "Aktif");
    }

    function getStudent(address studentAddress) external view returns (string memory, string memory, string memory, string memory, string memory, string memory){
        Biodata storage senderData = bio[studentAddress];
        return (senderData.name, senderData.nim, senderData.major, senderData.email, senderData.validityPeriod, senderData.status);
    }

    function processStudentDroput(address studentAddress, string memory studentName) public returns (bool) {
        Biodata storage senderData = bio[studentAddress];

        if(!(senderData.hasEnrolled)) {
            revert StudentNotEnrolled(studentAddress);
        }
        
        if(!checkWrapper.compareStrings(senderData.name, studentName)) {
            revert StudentNameMismatch(senderData.name, studentName);
        }
        
        // Check if already dropped out
        if(checkWrapper.compareStrings(senderData.status, "Dropout")) {
            revert StudentAlreadyDroppedOut(studentAddress);
        }

        string memory faculty = senderData.faculty;
        string memory major = senderData.major;
        uint idStudent = senderData.studentId;
        
        // Update counter in faculty and major contract
        try facultyAndMajor.decrementStudentCount(faculty, major) {
            senderData.status = "Dropout";
            emit StudentDroppedOut(idStudent, faculty, major);
            return true;
        } catch (bytes memory /*lowLevelData*/) {
            revert StudentCountError(faculty, major, "decrement student count");
        }        
    }
}


