// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Check} from "../libraries/Check.sol";
import {IFacultyAndMajor} from "../interfaces/IFacultyAndMajor.sol";

contract FacultyAndMajor is IFacultyAndMajor {

    struct Major {
        uint8 idMajor;
        string majorName;
        string middleNum;
        uint16 studentCount;
        uint cost;
    }

    struct Faculty {
        uint8 idFaculty;
        string facultyName;
        string abbreviationFaculty;
        mapping(string => Major) majors;
        string[] majorNames;
    }

    Faculty[] public facultyList;
    mapping(string => uint8) private facultyIndices;

    error FacultyNotFound(string faculty);
    error FacultyAlreadyExists(string faculty);
    error MajorNotFound(string major);
    error MajorAlreadyExists(string major);
    error EmptyInput(string field);
    error InvalidMiddleDigits(string middleNim);
    error HasExistingStudents(string student);

    function facultySearch(string memory facultyInput) internal view returns (bool, uint8) {
        uint8 index = facultyIndices[facultyInput];
        // Return true if faculty exists (index > 0), false otherwise
        return (index != 0, index > 0 ? index - 1 : 0);
    }

    function majorSearch(uint iterationFaculty, string memory majorInput) private view returns (bool, uint8){
        // Faculty storage faculty = facultyList[foundFaculty];
        uint8 idMajor = facultyList[iterationFaculty].majors[majorInput].idMajor;
        return (idMajor != 0, idMajor > 0 ? idMajor - 1 : 0);
        // if (faculty.majorNames.length != 0) {
        //     // Check if the major exists before subtracting
        //     if (faculty.majors[majorInput].idMajor > 0) {
        //         return (true, faculty.majors[majorInput].idMajor - 1);
        //     }
        // }
        // return (false, 0);
    }
    function costSearch(uint foundFaculty, string memory foundMajor) private view returns(uint){
        Faculty storage faculty = facultyList[foundFaculty];
        uint resultCost = faculty.majors[foundMajor].cost;
        return resultCost;
    }

    function addFaculty(string memory facultyInput, string memory abbreviation) external {
        if(bytes(facultyInput).length == 0) revert EmptyInput("Nama fakultas tidak boleh kosong");        
        string memory afterChecking = Check.capitalizeFirstLetters(facultyInput);

        (bool result,) = facultySearch(facultyInput);
        if(result) revert FacultyAlreadyExists(facultyInput);
        
        Faculty storage newFaculty = facultyList.push();
        uint8 facultyLength = uint8(facultyList.length);
        newFaculty.idFaculty = facultyLength;
        newFaculty.facultyName = afterChecking;
        newFaculty.abbreviationFaculty = abbreviation;
        facultyIndices[afterChecking] = facultyLength;
        emit NewFaculty(facultyLength, afterChecking, afterChecking, abbreviation);
    }

    function updateFaculty(string memory facultyInput, string memory changeName,string memory abbreviation) external {
        (bool foundFaculty, uint8 iterationFaculty) = facultySearch(facultyInput);
        if(bytes(changeName).length == 0) revert EmptyInput("Nama fakultas tidak boleh kosong");
        
        if(bytes(abbreviation).length == 0) revert EmptyInput("Singkatan fakultas tidak boleh kosong");
        if(!foundFaculty) revert FacultyNotFound(facultyInput);
        Faculty storage faculty = facultyList[iterationFaculty];
        faculty.facultyName = changeName;
        faculty.abbreviationFaculty = abbreviation;
        emit UpdateFaculty(iterationFaculty, facultyInput, changeName, changeName, abbreviation);
    }

    function removeFaculty(string memory facultyInput) external {
        (bool foundFaculty, uint8 iterationFaculty) = facultySearch(facultyInput);
        if(!foundFaculty) revert FacultyNotFound(facultyInput);

        Faculty storage faculty = facultyList[iterationFaculty];
        Faculty storage lastFaculty = facultyList[facultyList.length - 1];
        if(faculty.majorNames.length > 0) revert MajorAlreadyExists("Fakultas masih memiliki jurusan");
        
        // If it's not the last item, move the last item to the position of the removed item
        if (iterationFaculty < facultyList.length - 1) {
            // Copy the last faculty to the position of the faculty being removed
            faculty.idFaculty = lastFaculty.idFaculty;
            faculty.facultyName = lastFaculty.facultyName;
            faculty.abbreviationFaculty = lastFaculty.abbreviationFaculty;
            
            // Copy major names from the last faculty
            string[] storage lastMajorNames = lastFaculty.majorNames;
            uint8 majorCount = uint8(lastMajorNames.length);
        
            for (uint j = 0; j < majorCount; j++) {
                string memory majorName = lastMajorNames[j];
                faculty.majorNames.push(majorName);
                faculty.majors[majorName] = lastFaculty.majors[majorName];
            }

            // Update the faculty index mapping for the moved faculty
            facultyIndices[faculty.facultyName] = iterationFaculty;
        }
        // Remove the last element
        facultyList.pop();
        // Remove the faculty from the index mapping
        delete facultyIndices[facultyInput];
        emit RemoveFaculty(iterationFaculty, facultyInput);
    }

    function forChecking(string memory facultyInput, string memory majorInput) private view returns(uint8, uint8){
        (bool result, uint8 iterationFaculty) = facultySearch(facultyInput);
        if(!result) revert FacultyNotFound(facultyInput);
        
        (bool result2, uint8 iterationMajor) = majorSearch(iterationFaculty, majorInput);
        if(!result2) revert MajorNotFound(majorInput);
        
        return (iterationFaculty, iterationMajor);
    }

    function addMajor(string memory facultyInput, string memory majorInput, string memory inputMiddleNum, uint _cost) external override {
        if(bytes(inputMiddleNum).length == 0) revert EmptyInput("Middle NIM tidak boleh kosong");
        if(_cost == 0) revert EmptyInput("Biaya tidak boleh kosong");

        (bool result, uint8 iterationFaculty) = facultySearch(facultyInput);
        if(!result) revert FacultyNotFound(facultyInput);

        (bool result2, ) = majorSearch(iterationFaculty, majorInput);
        if(result2) revert MajorAlreadyExists(majorInput);

        emit NewMajor(0, facultyInput, majorInput, majorInput, inputMiddleNum, _cost);

        (bool isValid, string memory errorMessage) = Check.validateMiddleDigits(inputMiddleNum);
        if(!isValid) revert InvalidMiddleDigits(errorMessage);
        
        emit NewMajor(0, facultyInput, majorInput, majorInput, inputMiddleNum, _cost);
        Faculty storage faculty = facultyList[iterationFaculty];
        uint8 majorLength = uint8(faculty.majorNames.length) + 1;
        faculty.majors[majorInput] = Major({
            idMajor: majorLength,
            majorName: majorInput,
            middleNum: inputMiddleNum,
            studentCount: 0,
            cost: _cost
        });

        faculty.majorNames.push(majorInput);
        emit NewMajor(majorLength, facultyInput, majorInput, majorInput, inputMiddleNum, _cost);
    }

    function updateMajor(string memory facultyInput, string memory majorInput, string memory changeName, string memory inputMiddleNum, uint _cost) external override {
        // Validate inputs first
    
        if(bytes(changeName).length == 0) revert EmptyInput("Nama jurusan tidak boleh kosong");
        if(_cost == 0) revert EmptyInput("Biaya tidak boleh kosong");
        
        (bool isValid, string memory errorMessage) = Check.validateMiddleDigits(inputMiddleNum);
        if(!isValid) revert InvalidMiddleDigits(errorMessage);
        
        // Get indices once
        (uint8 iterationFaculty, uint iterationMajor) = forChecking(facultyInput, majorInput);
        
        // Cache storage references
        Faculty storage faculty = facultyList[iterationFaculty];
        Major storage major = faculty.majors[majorInput];
        
        // Update state
        major.majorName = changeName;
        major.middleNum = inputMiddleNum;
        major.cost = _cost;
        faculty.majorNames[iterationMajor] = changeName;
        
        // Emit event
        emit UpdateMajor(iterationMajor+1, facultyInput, majorInput, changeName, changeName, inputMiddleNum, _cost);
    }

    function removeMajor(string memory facultyInput, string memory majorInput) external override{
        (uint8 iterationFaculty, uint8 iterationMajor) = forChecking(facultyInput, majorInput);        
        Faculty storage faculty = facultyList[iterationFaculty];
        
        if(faculty.majors[majorInput].studentCount > 0) revert HasExistingStudents("Jurusan masih memiliki mahasiswa");
        delete faculty.majors[majorInput];
        uint8 length = uint8(faculty.majorNames.length);
        
        for (uint8 i = iterationMajor; i < length - 1; i++) {
            faculty.majorNames[i] = faculty.majorNames[i + 1];
        }
        faculty.majorNames.pop();
        emit RemoveMajor(iterationMajor, facultyInput, majorInput);
    }
    
    function getAbbreviation(string memory facultyInput) external override view returns (string memory){
        (bool result, uint8 iterationFaculty) = facultySearch(facultyInput);
        if(!result) revert FacultyNotFound(facultyInput);
    
        string memory resultAbbreviation = facultyList[iterationFaculty].abbreviationFaculty;
        return resultAbbreviation;
    }

    function getMajorMiddleNum(string memory facultyInput, string memory majorInput) external override view returns (string memory resultMiddleNum){
        (uint8 iterationFaculty, ) = forChecking(facultyInput, majorInput);
        resultMiddleNum = facultyList[iterationFaculty].majors[majorInput].middleNum;
    }

    function getMajorCost(string memory facultyInput, string memory majorInput) external override view returns (uint){
        (uint8 iterationFaculty, ) = forChecking(facultyInput, majorInput);        
        uint cost = costSearch(iterationFaculty, majorInput);
        return cost;
    }
    
    // note : add Math library by openzeppelin for increment and decrement 
    function incrementStudentCount(string memory facultyInput, string memory majorInput) external override returns(uint){
        (uint8 iterationFaculty, ) = forChecking(facultyInput, majorInput);
        Major storage major = facultyList[iterationFaculty].majors[majorInput];
        major.studentCount += 1;
        return major.studentCount;
    }

    function decrementStudentCount(string memory facultyInput, string memory majorInput) external override {
        (uint8 iterationFaculty, ) = forChecking(facultyInput, majorInput);
        Major storage major = facultyList[iterationFaculty].majors[majorInput];
        require(major.studentCount > 0, "Students count cannot be less than zero");
        major.studentCount -= 1;
    }

    function getMajorDetails(string memory facultyInput, string memory majorInput) external override view returns (uint8, string memory, string memory, uint16, uint){
        (uint8 iterationFaculty, ) = forChecking(facultyInput, majorInput);
        Major storage major = facultyList[iterationFaculty].majors[majorInput];
        return (major.idMajor, major.majorName, major.middleNum, major.studentCount, major.cost);
    }

    function listMajors(string memory facultyInput) external override view returns (string[] memory) {
        (bool found, uint8 iterationFaculty) = facultySearch(facultyInput);
        if(!found) revert FacultyNotFound("Fakultas tidak ditemukan");
        return facultyList[iterationFaculty].majorNames;
    }
    
    function listFaculties() external override view returns (string[] memory){
        string[] memory getFacultyName = new string[](facultyList.length);
        uint8 length = uint8(facultyList.length);
        for(uint8 i = 0; i < length; i++){
            getFacultyName[i] = facultyList[i].facultyName;
        }
        
        return getFacultyName;
    }
    
}        