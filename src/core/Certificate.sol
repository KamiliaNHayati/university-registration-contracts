// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IStudents} from "../interfaces/IStudents.sol";

/// @title University Certificate NFT
/// @notice ERC721 NFT certificates for graduated students
contract Certificate is ERC721 {
    /* Public State Variables */
    IStudents public students;
    uint256 public tokenIdCounter;
    mapping(address => bool) public hasClaimed;
    
    /* Error */
    error NotGraduated();
    error AlreadyClaimed();

    /* Event */
    event CertificateMinted(address indexed student, uint256 tokenId);
    
    /* Constructor */
    constructor(address _students) ERC721("University Certificate", "CERT") {
        students = IStudents(_students);
    }
    
    /* Function */
    /// @notice Mint a certificate NFT for graduated students
    function mintCertificate() external {
        if (!students.hasGraduated(msg.sender)) revert NotGraduated();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        
        uint256 tokenId = tokenIdCounter++;
        hasClaimed[msg.sender] = true;
        _mint(msg.sender, tokenId);    
        emit CertificateMinted(msg.sender, tokenId);
    }
}