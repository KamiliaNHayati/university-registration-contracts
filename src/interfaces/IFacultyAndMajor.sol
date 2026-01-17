// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFacultyAndMajor {
    function addFaculty(string memory facultyName, string memory abbreviation) external;
    function updateFaculty(string memory currentFacultyName, string memory newFacultyName, string memory abbreviation) external;
    function removeFaculty(string memory facultyName) external;

    function addMajor(string memory facultyName, string memory majorName, string memory middleNim, uint cost) external;
    function updateMajor(string memory facultyName, string memory majorName, string memory newMajorName, string memory middleNim, uint cost) external;
    function removeMajor(string memory facultyName, string memory majorName) external;

    function getAbbreviation(string memory facultyName) external view returns (string memory);
    function getMajorMiddleNum(string memory facultyName, string memory majorName) external view returns (string memory);
    function getMajorCost(string memory facultyName, string memory majorName) external view returns (uint);
    function getMajorDetails(string memory facultyInput, string memory majorInput) external view returns (uint8, string memory, string memory, uint16, uint);

    function incrementStudentCount(string memory facultyName, string memory majorName) external returns (uint);
    function decrementStudentCount(string memory facultyName, string memory majorName) external;

    function listMajors(string memory facultyName) external view returns (string[] memory);
    function listFaculties() external view returns (string[] memory);
    
    event NewFaculty(uint indexed facultyId, string indexed facultyName, string facultyNameDisplay, string abbreviation);
    event UpdateFaculty(uint indexed facultyId, string oldFacultyName, string indexed newFacultyName, string newFacultyNameDisplay, string abbreviation);
    event RemoveFaculty(uint indexed facultyId, string facultyName);
    event NewMajor(uint indexed majorId, string facultyName, string indexed majorName, string majorNameDisplay, string middleNim, uint cost);
    event UpdateMajor(uint indexed majorId, string facultyName, string oldMajorName, string indexed newMajorName, string newMajorNameDisplay, string middleNim, uint cost);
    event RemoveMajor(uint indexed majorId, string facultyName, string majorName);
}


// pragma solidity ^0.8.20;

// import "../libraries/Check.sol";
// import "../interface/IFacultyAndMajor.sol";

// contract FacultyAndMajor is IFacultyAndMajor {

//     struct Major {
//         uint idMajor;
//         string majorName;
//         string middleNim;
//         uint studentsCount;
//         uint cost;
//     }

//     struct Faculty {
//         uint idFaculty;
//         string facultyName;
//         string abbreviationFaculty;
//         Major[] major;
//     }

//     Faculty[] public facultyList;

//     function facultySearch(string memory facultyInput) private view returns (bool, uint8){
//         uint length = facultyList.length;
//         for(uint8 i = 0; i < length; i++){
//             if(Check.compareStrings(facultyList[i].facultyName, facultyInput)){
//                 return (true, i);
//             }
//         }
//         return (false, 0);
//     }
    
//     function majorSearch(uint foundFaculty, string memory majorInput) private view returns (bool, uint8){
//         Faculty storage faculty = facultyList[foundFaculty];
//         uint length = faculty.major.length;
//         for(uint8 i = 0; i < length; i++){
//             if(Check.compareStrings(majorInput, faculty.major[i].majorName)){
//                 return (true, i);
//             }
//         }
//         return (false, 0);
//     }

//     function costSearch(uint foundFaculty, uint foundMajor) private view returns(uint){
//         Faculty storage faculty = facultyList[foundFaculty];
//         uint resultCost = faculty.major[foundMajor].cost;
//         return resultCost;
//     }

//     function addFaculty(string memory facultyInput, string memory abbreviation) external {
//         (bool result,) = facultySearch(facultyInput);
//         require(!result, "Fakultas sudah tersedia");
//         string memory afterChecking = Check.checkCapitalLetters(facultyInput);
//         uint facultyLength = facultyList.length;
//         Faculty storage newFaculty = facultyList.push();
//         newFaculty.idFaculty = facultyLength;
//         newFaculty.facultyName = afterChecking;
//         newFaculty.abbreviationFaculty = abbreviation;
//         emit OutputFaculty(facultyLength, facultyInput, facultyInput, abbreviation);
//     }

//     function updateFaculty(string memory facultyInput, string memory changeName,string memory abbreviation) external {
//         (bool foundFaculty, uint8 iterationFaculty) = facultySearch(facultyInput);
//         require(foundFaculty, "Fakultas tidak ditemukan");
//         Faculty storage faculty = facultyList[iterationFaculty];
//         faculty.facultyName = changeName;
//         faculty.abbreviationFaculty = abbreviation;
//         emit UpdateFaculty(iterationFaculty, facultyInput, changeName, changeName, abbreviation);
//     }

//     function removeFaculty(string memory facultyInput) external {
//         (bool foundFaculty, uint8 iterationFndFclty) = facultySearch(facultyInput);
//         require(foundFaculty, "Fakultas tidak ditemukan");
//         uint length = facultyList.length;
//         for(uint8 i = iterationFndFclty; i < length - 1; i++){
//             facultyList[i] = facultyList[i+1];
//         }
//         facultyList.pop();
//         emit RemoveFaculty(iterationFndFclty, facultyInput);
//     }

//     function forChecking(string memory facultyInput, string memory majorInput) private view returns(uint8, uint8){
//         (bool result, uint8 iterationFaculty) = facultySearch(facultyInput);
//         require(result, "Fakultas tidak tersedia");
//         (bool result2, uint8 iterationMajor) = majorSearch(iterationFaculty, majorInput);
//         require(result2, "Jurusan tidak tersedia");
//         return (iterationFaculty, iterationMajor);
//     }

//     function addMajor(string memory facultyInput, string memory majorInput, string memory inputMiddleNim, uint _cost) external override {
//         (bool result, uint8 iterationFaculty) = facultySearch(facultyInput);
//         require(result, "Fakultas tidak tersedia");
//         (bool result2, ) = majorSearch(iterationFaculty, majorInput);
//         require(!result2, "Jurusan sudah tersedia");
//         require(Check.middleDigitsNim(inputMiddleNim), "Tidak boleh lebih dari 4 digit");
//         Faculty storage faculty = facultyList[iterationFaculty];
//         uint majorLength = faculty.major.length;
//         faculty.major.push(Major({
//             idMajor: majorLength,
//             majorName : majorInput,
//             middleNim : inputMiddleNim,
//             studentsCount : 0,
//             cost : _cost       
//         }));
//         emit OutputMajor(majorLength, facultyInput, majorInput, majorInput, inputMiddleNim, _cost);
//     }

//     function updateMajor(string memory facultyInput, string memory majorInput, string memory changeName, string memory inputMiddleNim, uint _cost) external override{
//         (uint8 iterationFndFclty, uint8 iterationFndMjr) = forChecking(facultyInput, majorInput);
//         require(Check.middleDigitsNim(inputMiddleNim), "Tidak boleh lebih dari 4 digit");
//         Faculty storage faculty = facultyList[iterationFndFclty];
//         faculty.major[iterationFndMjr].majorName = changeName;
//         faculty.major[iterationFndMjr].middleNim = inputMiddleNim;
//         faculty.major[iterationFndMjr].cost = _cost;
//         emit UpdateMajor(iterationFndMjr, facultyInput, majorInput, changeName, changeName, inputMiddleNim, _cost);
//     }

//     function removeMajor(string memory facultyInput, string memory majorInput) external override{
//         (uint8 iterationFndFclty, uint8 iterationFndMjr) = forChecking(facultyInput, majorInput);
//         Faculty storage faculty = facultyList[iterationFndFclty];
//         uint length = faculty.major.length;
//         for(uint8 i = iterationFndMjr; i < length - 1; i++){
//             faculty.major[i] = faculty.major[i+1];
//         }
//         faculty.major.pop();
//         emit RemoveMajor(iterationFndMjr, facultyInput, majorInput);
//     }
    
//     function getAbbreviation(string memory facultyInput) external override view returns (string memory){
//         (bool result, uint8 iterationFoundFaculty) = facultySearch(facultyInput);
//         require(result, "Fakultas tidak tersedia");
//         string memory resultAbbreviation = facultyList[iterationFoundFaculty].abbreviationFaculty;
//         return resultAbbreviation;
//     }    

//     function getNimMiddleOfTheMajor(string memory chooseFaculty, string memory chooseMajor) external override view returns (string memory resultMiddleNim){
//         (bool result, uint8 iterationFoundFaculty) = facultySearch(chooseFaculty);
//         require(result, "Fakultas tidak tersedia");
//         ( , uint8 iterationFoundMajor) = majorSearch(iterationFoundFaculty, chooseMajor);
//         resultMiddleNim = facultyList[iterationFoundFaculty].major[iterationFoundMajor].middleNim;
//     }

//     function majorSearchAnotherContract(string memory facultyInput, string memory majorInput) external override view returns(bool){
//         (bool foundFaculty, uint8 iterationFaculty) = facultySearch(facultyInput);
//         require(foundFaculty, "Fakultas tidak ditemukan");
//         (bool result, ) = majorSearch(iterationFaculty, majorInput);
//         return result;
//     }

//     function costAnotherContract(string memory facultyInput, string memory majorInput) external override view returns (uint){
//        (bool foundFaculty, uint8 iterationFaculty) = facultySearch(facultyInput);
//         require(foundFaculty, "Fakultas tidak ditemukan");
//         (bool foundMajor, uint8 iterationMajor) = majorSearch(iterationFaculty, majorInput);
//         require(foundMajor, "Jurusan tidak ditemukan");
//         uint cost = costSearch(iterationFaculty, iterationMajor);
//         return cost;
//     }

//     function increaseStudentsCount(string memory facultyInput, string memory majorInput) external override returns(uint){
//         ( , uint8 iterationFoundFaculty) = facultySearch(facultyInput);
//         ( , uint8 iterationFoundMajor) = majorSearch(iterationFoundFaculty, majorInput);
//         uint resultStudentsCount = ++facultyList[iterationFoundFaculty].major[iterationFoundMajor].studentsCount;
//         return resultStudentsCount;
//     }

//     function decreaseStudentsCount(string memory facultyInput, string memory majorInput) external override{
//         ( , uint8 iterationFoundFaculty) = facultySearch(facultyInput);
//         ( , uint8 iterationFoundMajor) = majorSearch(iterationFoundFaculty, majorInput);
//         --facultyList[iterationFoundFaculty].major[iterationFoundMajor].studentsCount;
//     }

//     function getMajorOfTheFaculty(string memory chooseFaculty) external override view returns (string[] memory){
//         (bool result, uint8 iterationFoundFaculty) = facultySearch(chooseFaculty);
//         require(result, "Fakultas tidak tersedia");
//         Faculty storage faculty = facultyList[iterationFoundFaculty];        
//         string[] memory getMajorName = new string[](faculty.major.length);
//         uint length = faculty.major.length;
//         for(uint i = 0; i < length; i++){
//             getMajorName[i] = faculty.major[i].majorName;
//         }
//         return getMajorName;
//     }

//     function getAllFaculty() external override view returns (string[] memory){
//         string[] memory getFacultyName = new string[](facultyList.length);
//         uint length = facultyList.length;
//         for(uint i = 0; i < length; i++){
//             getFacultyName[i] = facultyList[i].facultyName;
//         }
//         return getFacultyName;
//     }
    
// }        