// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRoleManager {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getDefaultAdminRole() external view returns (bytes32);
    function getFacultyAdminRole() external view returns (bytes32);
    function getRegistrarRole() external view returns (bytes32);
    function acceptPayment(address sender) external payable;

    event PaymentAccepted(address indexed sender, uint256 amount);
}