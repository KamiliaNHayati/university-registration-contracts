// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFacultyAndMajor} from "../interfaces/IFacultyAndMajor.sol";
import {Check} from "../libraries/Check.sol";
import {Email} from "../libraries/Email.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary} from "@bokkypoobahs/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {OwnerControlled} from "../access/OwnerControlled.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {IStudents} from "../interfaces/IStudents.sol";

/// @title Student Enrollment Contract
/// @notice Manages student enrollment with Chainlink Automation
contract Students is OwnerControlled, AutomationCompatibleInterface, IStudents{

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
        uint16 gpa;  
    }

    /* Public State Variables */
    bool public isOpen;
    uint8 public minimumMonth;
    uint8 public maximumMonth;
    uint8 public maximumApply;
    mapping(address => Application[]) public applications;
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
    event ApplicationSubmitted(address applicant);
    event ApplicationApproved(address applicant);
    event ApplicationRejected(address applicant);
    event ValidityPeriodUpdated(uint8 month, uint8 day, uint8 yearOffset);
    event StudentGPAUpdated(address indexed student, uint16 gpa);
    event EnrollmentMonthsUpdated(uint8 minimumMonth, uint8 maximumMonth);
    event FacultyAndMajorUpdated(address indexed facultyAndMajor);
    event StudentGraduated(address indexed student, string studentId);

    /* Errors */
    error AlreadyEnrolled(address student);
    error StudentAlreadyDroppedOut(address student);
    error EnrollmentClosed();
    error InvalidPaymentAmount(uint256 sent, uint256 required);
    error StudentNotEnrolled(address student);
    error StudentNameMismatch(string provided, string stored);
    error InvalidEnrollmentPeriod();
    error NonOnlyOwner();
    error NotApproved();
    error UpkeepNotNeeded();
    error InvalidGPA(uint16 gpa);
    error NotEligibleForGraduation(address student, uint8 currentSemester);
    error GPATooLow(uint16 gpa);
    error MaxApplicationsExceeded(uint8 current, uint8 max);
    error AlreadyApplied(string majorName);
    error AlreadyApproved(address applicant, string majorName);
    
    constructor(
        address _facultyAndMajor,
        uint8 _minimumMonth,
        uint8 _maximumMonth,
        uint8 _validityEndMonth,
        uint8 _validityEndDay,
        uint8 _validityYearOffset,
        uint8 _maximumApply
    ) {
        facultyAndMajor = IFacultyAndMajor(_facultyAndMajor);
        minimumMonth = _minimumMonth;
        maximumMonth = _maximumMonth;
        validityEndMonth = _validityEndMonth;
        validityEndDay = _validityEndDay;
        validityYearOffset = _validityYearOffset;
        maximumApply = _maximumApply;
    }

    /* External Functions */
    // Chainlink Automation calls this when checkUpkeep returns true
    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded();  // Optional: add this error
        }
        
        if (_isWithinEnrollmentMonths()) {
            isOpen = true;
        } else {
            isOpen = false;
        }
    }

    /// @notice Apply for enrollment in a faculty and major
    function applyForEnrollment(
        string calldata studentName, 
        string calldata facultyName, 
        string calldata majorName
    ) 
        external  
    {
        if(msg.sender == owner()) revert NonOnlyOwner();
        if (!isOpen) revert EnrollmentClosed();
        facultyAndMajor.getMajorDetails(facultyName, majorName);
        
        uint8 currentApply = uint8(applications[msg.sender].length);
        if (currentApply >= maximumApply) revert MaxApplicationsExceeded(currentApply, maximumApply);
        _findAlreadyApply(majorName);

        Check.validateOnlyLettersAndSpaces(studentName);
        Check.validateOnlyLettersAndSpaces(facultyName);
        Check.validateOnlyLettersAndSpaces(majorName);

        applications[msg.sender].push(Application({
            applicant: msg.sender, 
            name: studentName, 
            faculty: facultyName, 
            major: majorName, 
            status: ApplicationStatus.Pending
        }));
        applicantIndex[msg.sender] = pendingApplicants.length;
        pendingApplicants.push(msg.sender);
        emit ApplicationSubmitted(msg.sender);
    }

    /// @notice Approve or reject a student's application
    function updateApplicationStatus(
        address applicant, 
        string memory majorName, 
        ApplicationStatus status
    ) 
        external 
        onlyOwner 
    {
        uint8 majorIndex = _findApplicationIndex(applicant, majorName);
        applications[applicant][majorIndex].status = status;
        if (status == ApplicationStatus.Approved) {
            _removeFromPendingList(applicant);
            emit ApplicationApproved(applicant);
        } else if (status == ApplicationStatus.Rejected) {
            emit ApplicationRejected(applicant);
        }
    }

    /// @notice Complete enrollment by paying the required fee
    function enrollStudent() external payable {
        uint8 majorIndex = _findApprovedApplication(msg.sender);
        Application storage app = applications[msg.sender][majorIndex];
        // Note: _findApprovedApplication already reverts if no approved application found

        if(!isOpen){
            revert InvalidEnrollmentPeriod();
        }

        Biodata storage studentData = studentRecords[msg.sender];

        if(studentData.hasEnrolled) revert AlreadyEnrolled(msg.sender);

        string memory studentName = app.name;
        string memory faculty = app.faculty;
        string memory major = app.major;

        _validateEnrollmentFee(msg.value, faculty, major);

        string memory name = Check.capitalizeFirstLetters(studentName);
        string memory email = _generateStudentEmail(name);
        string memory id = _generateStudentId(faculty, major);
        string memory validityPeriod = _calculateValidityPeriod();

        studentRecords[msg.sender] = Biodata({
            studentId: id, 
            enrollmentTime: block.timestamp, 
            name: name, 
            email: email, 
            major: major, 
            faculty: faculty, 
            semester: 1, 
            status: StudentStatus.Active, 
            validityPeriod: validityPeriod, 
            hasEnrolled: true,
            gpa: 0
        });
        enrolledStudents.push(msg.sender);
        emit StudentEnrolled(id, faculty, major, StudentStatus.Active);
    }

    /// @notice Process a student's dropout request
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
    function setValidityPeriod(uint8 month, uint8 day, uint8 yearOffset) 
        external 
        onlyOwner 
    {
        require(month >= 1 && month <= 12, "Invalid month");
        require(day >= 1 && day <= 31, "Invalid day");
        require(yearOffset >= 1 && yearOffset <= 7, "Invalid year offset");
        
        validityEndMonth = month;
        validityEndDay = day;
        validityYearOffset = yearOffset;
        emit ValidityPeriodUpdated(month, day, yearOffset);
    }

    /// @notice Set the enrollment period months (e.g., month 6 to 8 for June-August)
    function setEnrollmentMonths(uint8 _minimumMonth, uint8 _maximumMonth) 
        external 
        onlyOwner 
    {
        require(_minimumMonth >= 1 && _minimumMonth <= 12, "Invalid minimum month");
        require(_maximumMonth >= 1 && _maximumMonth <= 12, "Invalid maximum month");
        require(_minimumMonth <= _maximumMonth, "Min must be <= max");
        
        minimumMonth = _minimumMonth;
        maximumMonth = _maximumMonth;
        emit EnrollmentMonthsUpdated(_minimumMonth, _maximumMonth);
    }

    /// @notice Update the FacultyAndMajor contract address
    function setFacultyAndMajor(address _facultyAndMajor) external onlyOwner {
        require(_facultyAndMajor != address(0), "Invalid address");
        facultyAndMajor = IFacultyAndMajor(_facultyAndMajor);
        emit FacultyAndMajorUpdated(_facultyAndMajor);
    }

    /// @notice Update a student's GPA (stored as 350 = 3.50)
    function updateStudentGPA(address student, uint16 gpa) external onlyOwner {
        if (gpa > 400) revert InvalidGPA(gpa); 
        studentRecords[student].gpa = gpa;
        emit StudentGPAUpdated(student, gpa);
    }

    /// @notice Graduate a student who meets requirements
    function graduateStudent(address student) external onlyOwner {
        if (studentRecords[student].semester < 7) {
            revert NotEligibleForGraduation(student, studentRecords[student].semester);
        }
        if (studentRecords[student].gpa < 200) {  // Optional: also check GPA
            revert GPATooLow(studentRecords[student].gpa);
        }
        
        studentRecords[student].status = StudentStatus.Graduate;
        emit StudentGraduated(student, studentRecords[student].studentId);
    }

    function getStudent() 
        external 
        returns (string memory, string memory, string memory, string memory, string memory, uint8, StudentStatus, string memory){
        Biodata storage studentData = studentRecords[msg.sender];
        
        uint8 semester = _calculateSemester(studentData.enrollmentTime);
        studentData.semester = semester;

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

    /* External functions that are view */
    // Chainlink Automation calls this to check if upkeep is needed
    function checkUpkeep(bytes calldata) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory) 
    {
        bool shouldOpen = !isOpen && _isWithinEnrollmentMonths();
        bool shouldClose = isOpen && !_isWithinEnrollmentMonths();
        upkeepNeeded = shouldOpen || shouldClose;
        return (upkeepNeeded, "");
    }

    function getPendingApplicants() external view returns (address[] memory) {
        return pendingApplicants;
    }

    function hasGraduated(address student) external view returns (bool) {
        return studentRecords[student].status == StudentStatus.Graduate;
    }

    function getGPA(address student) external view returns (uint16) {
        return studentRecords[student].gpa;
    }

    function listEnrolledStudents() external view onlyOwner returns (address[] memory) {
        return enrolledStudents;
    }
    
    /* Private functions */
    // studentId = facultyCode + majorCode + studentOrder
    function _generateStudentId(string memory facultyName, string memory majorName) 
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
    function _isWithinEnrollmentMonths() private view returns (bool) {
        uint8 month = uint8(BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp));
        return month >= minimumMonth && month <= maximumMonth;
    }

    function _validateEnrollmentFee(uint value, string memory facultyName, string memory majorName) 
        private 
        view 
    {
        uint cost = facultyAndMajor.getMajorCost(facultyName, majorName);
        if(value != cost) revert InvalidPaymentAmount(value, cost);
    }

    function _findAlreadyApply(string memory majorName) private view {
        for(uint8 i = 0; i < applications[msg.sender].length; i++) {
            if(Check.compareStrings(applications[msg.sender][i].major, majorName)) {
                revert AlreadyApplied(majorName);
            }
        }
    }

    /// @notice Find application index by major name (for updating)
    function _findApplicationIndex(address applicant, string memory majorName) 
        private 
        view 
        returns(uint8) 
    {
        for(uint8 i = 0; i < applications[applicant].length; i++) {
            if(Check.compareStrings(applications[applicant][i].major, majorName) && applications[applicant][i].status == ApplicationStatus.Pending) {
                return i;  // Found, return index
            }
        }
        revert AlreadyApproved(applicant, majorName);  // Or create new error: ApplicationNotFound
    }

    /// @notice Find the index of an approved application for a student
    function _findApprovedApplication(address student) private view returns(uint8) {
        for(uint8 i = 0; i < applications[student].length; i++) {
            if(applications[student][i].status == ApplicationStatus.Approved) {
                return i;
            }
        }
        revert NotApproved();
    }

    function _calculateSemester(uint256 enrollmentTime) 
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


    function _generateStudentEmail(string memory name) 
        private 
        pure 
        returns(string memory) 
    {
        string memory formattedName = Email.convertSpacesToDots(name);
        return string.concat(formattedName, "@university.edu");
    }
    
    function _calculateValidityPeriod() private view returns(string memory) {
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
}


