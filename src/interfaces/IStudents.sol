// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStudents {
    event AddStudent(uint16 idStudent, string _faculty, string major, string validityPeriod, string);
    event StudentDroppedOut(uint indexed idStudent, string faculty, string indexed major);

    function getMajorCost(string memory faculty, string memory major) external view returns(uint);
    function enrollStudent(uint value, address sender, string memory _name, string memory _faculty, string memory _major) external;
    function getStudent(address sender) external view returns (string memory, string memory, string memory, string memory, string memory, string memory);
    function processStudentDroput(address studentAddress, string memory studentName) external returns (bool);
}