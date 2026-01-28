// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OwnerControlled is Ownable {
    // event LogProcessPayment(string message, address indexed sender, uint256 amount);
    error DeclinePayment(string message);
    error FailedToSend();

    constructor() Ownable(msg.sender) {
    }

    receive() external payable {
        revert DeclinePayment("Use processPayment");
    }

    fallback() external payable {
        revert DeclinePayment("Use processPayment");
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        if(!success) revert FailedToSend();
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;   
    }
}
