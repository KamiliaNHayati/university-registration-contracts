// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFacultyAndMajor} from "../interfaces/IFacultyAndMajor.sol";
import {Check} from "../libraries/Check.sol";
import {Email} from "../libraries/Email.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {OwnerControlled} from "../access/OwnerControlled.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Students is OwnerControlled, AutomationCompatibleInterface{

    // ----------------------------
    // Type declarations
    // ----------------------------
    /* enum */
    enum ApplicationStatus { 
        Pending, 
        Approved, 
        Rejected, 
        Enrolled 
    }

    enum StudentStatus {
        Active,
        Graduate,
        Dropout
    }
    
    /* struct */
    struct Application {
        address applicant;
        string name;
        string faculty;
        string major;
        ApplicationStatus status;
    }

    struct Biodata {
        string studentId;
        uint enrollmentTime;
        string name;
        string email;
        string major;
        string faculty;
        uint8 semester;
        StudentStatus status;
        string validityPeriod;
        bool hasEnrolled;
    }

    /* Public State Variables */
    bool public isOpen;
    uint8 public minimumMonth;
    uint8 public maximumMonth;
    mapping(address => Application) public applications;
    uint8 public validityEndMonth;     
    uint8 public validityEndDay;
    uint8 public validityYearOffset;    // 4 years from enrollment
    address[] public pendingApplicants;
    address[] public enrolledStudents;
    mapping(address => uint256) public applicantIndex;

    /* Private State Variables */
    mapping(address => Biodata) private studentRecords;
    IFacultyAndMajor private facultyAndMajor;

    /* Events */
    event StudentEnrolled(string studentId, string faculty, string major, StudentStatus status);
    event StudentDroppedOut(string studentId, string faculty, string major);
    event SemesterUpdated(uint8 indexed semester);
    event ApplicationSubmitted(address applicant);
    event ApplicationApproved(address applicant);
    event ApplicationRejected(address applicant);
    event ValidityPeriodUpdated(uint8 month, uint8 day, uint8 yearOffset);

    /* Errors */
    error AlreadyEnrolled(address student);
    error StudentAlreadyDroppedOut(address student);
    error EnrollmentClosed();
    error InvalidPaymentAmount(uint256 sent, uint256 required);
    error MajorOperationFailed(string faculty, string major, string reason);
    error StudentNotEnrolled(address student);
    error StudentNameMismatch(string provided, string stored);
    error InvalidEnrollmentPeriod();
    error NimGenerationFailed(string faculty, string major, string reason);
    error StudentCountError(string faculty, string major, string reason);
    error NonOnlyOwner();
    error NotApproved();
    error UpkeepNotNeeded();
    
    constructor(address _facultyAndMajor, uint8 _minimumMonth, uint8 _maximumMonth, uint8 _validityEndMonth, uint8 _validityEndDay, uint8 _validityYearOffset) {
        facultyAndMajor = IFacultyAndMajor(_facultyAndMajor);
        minimumMonth = _minimumMonth;
        maximumMonth = _maximumMonth;
        validityEndMonth = _validityEndMonth;
        validityEndDay = _validityEndDay;
        validityYearOffset = _validityYearOffset;
    }

    /* External Functions */
    // Chainlink Automation calls this when checkUpkeep returns true
    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded();  // Optional: add this error
        }
        
        if (isWithinEnrollmentMonths()) {
            isOpen = true;
        } else {
            isOpen = false;
        }
    }

    // Step 1: Apply (no payment)
    function applyForEnrollment(string calldata studentName, string calldata facultyName, string calldata majorName) 
        external  
    {
        if(msg.sender == owner()) revert NonOnlyOwner();
        if (!isOpen) revert EnrollmentClosed();

        Check.validateOnlyLettersAndSpaces(studentName);
        Check.validateOnlyLettersAndSpaces(facultyName);
        Check.validateOnlyLettersAndSpaces(majorName);

        applications[msg.sender] = Application(msg.sender, studentName, facultyName, majorName, ApplicationStatus.Pending);
        applicantIndex[msg.sender] = pendingApplicants.length;
        pendingApplicants.push(msg.sender);
        emit ApplicationSubmitted(msg.sender);
    }

    // Step 2: Admin approves or rejects
    function updateApplicationStatus(address applicant, ApplicationStatus status) external onlyOwner {
        applications[applicant].status = status;
        if (status == ApplicationStatus.Approved) {
            _removeFromPendingList(applicant);
            emit ApplicationApproved(applicant);
        } else if (status == ApplicationStatus.Rejected) {
            emit ApplicationRejected(applicant);
        }
    }

    function enrollStudent() external payable {
        Application storage app = applications[msg.sender];

        if(!(app.status == ApplicationStatus.Approved)){
            revert NotApproved();
        }

        if(!isOpen){
            revert InvalidEnrollmentPeriod();
        }

        Biodata storage studentData = studentRecords[msg.sender];

        if(studentData.hasEnrolled) revert AlreadyEnrolled(msg.sender);

        string memory studentName = app.name;
        string memory faculty = app.faculty;
        string memory major = app.major;

        validateEnrollmentFee(msg.value, faculty, major);

        string memory name = Check.capitalizeFirstLetters(studentName);
        string memory email = generateStudentEmail(name);
        string memory id = generateStudentId(faculty, major);
        string memory validityPeriod = calculateValidityPeriod();

        studentRecords[msg.sender] = Biodata(
            id, 
            block.timestamp, 
            name, 
            email, 
            major, 
            faculty, 
            1, 
            StudentStatus.Active, 
            validityPeriod, 
            true);
    
        enrolledStudents.push(msg.sender);
        emit StudentEnrolled(id, faculty, major, StudentStatus.Active);
    }

    function processStudentDropout(string calldata studentName) external {
        Biodata storage studentData = studentRecords[msg.sender];

        if(!(studentData.hasEnrolled)) {
            revert StudentNotEnrolled(msg.sender);
        }
        
        if(!Check.compareStrings(studentName, studentData.name)) {
            revert StudentNameMismatch(studentName, studentData.name);
        }
        
        // Check if already dropped out
        if(studentData.status == StudentStatus.Dropout) {
            revert StudentAlreadyDroppedOut(msg.sender);
        }

        string memory faculty = studentData.faculty;
        string memory major = studentData.major;
        string memory studentId = studentData.studentId;
        
        facultyAndMajor.decrementStudentCount(faculty, major);
        studentData.status = StudentStatus.Dropout;
        emit StudentDroppedOut(studentId, faculty, major);
    }

    // Setter
    function setValidityPeriod(uint8 month, uint8 day, uint8 yearOffset) external onlyOwner {
        require(month >= 1 && month <= 12, "Invalid month");
        require(day >= 1 && day <= 31, "Invalid day");
        require(yearOffset >= 1 && yearOffset <= 7, "Invalid year offset");
        
        validityEndMonth = month;
        validityEndDay = day;
        validityYearOffset = yearOffset;
        emit ValidityPeriodUpdated(month, day, yearOffset);
    }


    /* External functions that are view */
    function getStudent() 
        external 
        view
        returns (string memory, string memory, string memory, string memory, string memory, uint8, StudentStatus, string memory){
        Biodata storage studentData = studentRecords[msg.sender];
        
        uint8 semester = calculateSemester(studentData.enrollmentTime);

        return (
            studentData.studentId,
            studentData.name,
            studentData.email,
            studentData.faculty,
            studentData.major,
            semester,
            studentData.status,
            studentData.validityPeriod
        );
    }

    // Chainlink Automation calls this to check if upkeep is needed
    function checkUpkeep(bytes calldata) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory) 
    {
        bool shouldOpen = !isOpen && isWithinEnrollmentMonths();
        bool shouldClose = isOpen && !isWithinEnrollmentMonths();
        upkeepNeeded = shouldOpen || shouldClose;
        return (upkeepNeeded, "");
    }

    function getPendingApplicants() external view returns (address[] memory) {
        return pendingApplicants;
    }

    function listEnrolledStudents() external view onlyOwner returns (address[] memory) {
        return enrolledStudents;
    }
    
    /* Private functions */
    // studentId = facultyCode + majorCode + studentOrder
    function generateStudentId(string memory facultyName, string memory majorName) 
        private 
        returns (string memory) 
    {
        uint studentOrder = facultyAndMajor.incrementStudentCount(facultyName, majorName);
        string memory lastDigits;

        if (studentOrder >= 1 && studentOrder < 100) {
            lastDigits = string.concat("00", Strings.toString(studentOrder));
        }
        else if(studentOrder >= 10 && studentOrder < 100) {
            lastDigits = string.concat("0", Strings.toString(studentOrder));
        }
        else {
            lastDigits = Strings.toString(studentOrder);
        }
        
        return string.concat(facultyAndMajor.getFacultyCode(facultyName), facultyAndMajor.getMajorCode(facultyName, majorName), lastDigits);  // "010140100"
    }

    /* Private functions that are view*/
    function isWithinEnrollmentMonths() private view returns (bool) {
        uint8 month = uint8(BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp));
        return month >= minimumMonth && month <= maximumMonth;
    }

    function generateStudentEmail(string memory name) 
        private 
        pure 
        returns(string memory) 
    {
        string memory formattedName = Email.convertSpacesToDots(name);
        return string.concat(formattedName, "@university.edu");
    }
    
    function calculateValidityPeriod() private view returns(string memory) {
        uint expirationYear = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp) + validityYearOffset;
        
        string memory monthName;
        if (validityEndMonth == 1) monthName = "January";
        else if (validityEndMonth == 2) monthName = "February";
        else if (validityEndMonth == 3) monthName = "March";
        else if (validityEndMonth == 4) monthName = "April";
        else if (validityEndMonth == 5) monthName = "May";
        else if (validityEndMonth == 6) monthName = "June";
        else if (validityEndMonth == 7) monthName = "July";
        else if (validityEndMonth == 8) monthName = "August";
        else if (validityEndMonth == 9) monthName = "September";
        else if (validityEndMonth == 10) monthName = "October";
        else if (validityEndMonth == 11) monthName = "November";
        else if (validityEndMonth == 12) monthName = "December";
        
        return string.concat(
            "Valid until ", 
            monthName, " ", 
            Strings.toString(validityEndDay), ", ", 
            Strings.toString(expirationYear)
        );
    }

    function validateEnrollmentFee(uint value, string memory facultyName, string memory majorName) 
        private 
        view 
    {
        uint cost = facultyAndMajor.getMajorCost(facultyName, majorName);
        if(value != cost) revert InvalidPaymentAmount(value, cost);
    }

    
    function calculateSemester(uint256 enrollmentTime) 
        private 
        view 
        returns (uint8) 
    {
        uint256 monthsEnrolled = (block.timestamp - enrollmentTime) / 30 days;
        uint8 semester = uint8((monthsEnrolled / 6) + 1);
        return semester > 12 ? 12 : semester;  // Cap at 12
    }

    function _removeFromPendingList(address applicant) internal {
        uint256 index = applicantIndex[applicant];
        uint256 lastIndex = pendingApplicants.length - 1;
        
        if (index != lastIndex) {
            address lastApplicant = pendingApplicants[lastIndex];
            pendingApplicants[index] = lastApplicant;
            applicantIndex[lastApplicant] = index;
        }
        
        pendingApplicants.pop();
        delete applicantIndex[applicant];
    }

}


