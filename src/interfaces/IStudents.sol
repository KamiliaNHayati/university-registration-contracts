// src/interfaces/IStudents.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStudents {
    function hasGraduated(address student) external view returns (bool);
    function getGPA(address student) external view returns (uint16);
}