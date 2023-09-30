// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ThoughtEdition.sol";
import "./IThoughtEdition.sol";
import "./IThoughtEditionFactory.sol";
import "../standard/Clones.sol";
import "../standard/Ownable.sol";


contract ThoughtEditionFactory is Ownable, IThoughtEditionFactory {
    address public implementation;
    string private editionBaseURI;

    // Mapping to store the editions published by each author
    mapping(address => address[]) public authorToEditions;

    // Mapping to track used salts
    mapping(bytes32 => bool) public salts;

    // Mapping to authors with their unique usernames
    mapping(string => IThoughtEditionFactory.AuthorDetails) public authors;

    // Mapping to author's address with their unique usernames
    mapping(address => string) public authorAddressToUserName;

    constructor(string memory _editionBaseURI) Ownable(msg.sender) {
        editionBaseURI = _editionBaseURI;
        // Set implementation contract.
        implementation = address(new ThoughtEdition(address(this), editionBaseURI));
    }

    /// @notice Deploy a new writing edition clone with the sender as the owner.
    /// @param edition edition parameters used to deploy the clone.
    function createEdition(IThoughtEdition.ThoughtEdition memory edition) override external returns (address clone) {
        clone = deployCloneAndInitialize(msg.sender, edition);
    }

    // Function to create a new blog
    function deployCloneAndInitialize(address owner, IThoughtEdition.ThoughtEdition memory edition) internal returns (address clone) {
        // Generate a unique salt for deterministic deployment
        bytes32 salt = keccak256(abi.encodePacked(owner, edition.title, edition.description, edition.contentURI));

        // Check if the salt has already been used
        require(!salts[salt], "Edition with the same salt already exists");

        // Mark the salt as used
        salts[salt] = true;

        // Use Clones.cloneDeterministic to create a new TaleEdition clone
        clone = Clones.cloneDeterministic(implementation, salt);

        // Initialize the blog with the provided parameters
        ThoughtEdition(clone).initialize(owner, edition);

        // Store the address of the created blog for the author
        authorToEditions[msg.sender].push(clone);

        emit CloneDeployed(msg.sender, owner, clone);

        return clone;
    }

    // Function to get the number of editions published by an author
    function getAuthorEditionsCount(address author) override external view returns (uint256) {
        return authorToEditions[author].length;
    }

    // Function to get the address of a specific edition published by an author
    function getAuthorEdition(address author, uint256 index) override external view returns (address) {
        require(index < authorToEditions[author].length, "Index out of range");
        return authorToEditions[author][index];
    }

    // Function to get the addresses of editions published by an author
    function getAuthorEditions(address author) override external view returns (address[] memory) {
        return authorToEditions[author];
    }

    // Function to check if a username is available
    function isUsernameAvailable(string memory userName) public view returns (bool) {
        return authors[userName].walletAddress == address(0);
    }

    // Function to fetch author details from userName
    function getAuthorDetails(string memory userName) public view returns (IThoughtEditionFactory.AuthorDetails memory) {
        return authors[userName];
    }

    // Function to fetch author details 
    function getAuthorDetails() public view returns (IThoughtEditionFactory.AuthorDetails memory) {
        return authors[authorAddressToUserName[msg.sender]];
    }

    // Function to fetch author userName 
    function getAuthorUserName() public view returns (string memory) {
        return authorAddressToUserName[msg.sender];
    }

    // Function to register author
    function registerAuthor(string memory userName, string memory name) public {
       require(isUsernameAvailable(userName), "Username is already taken");
        
        IThoughtEditionFactory.AuthorDetails memory author = IThoughtEditionFactory.AuthorDetails({
            userName: userName,
            name: name,
            walletAddress: msg.sender
        });

        authors[userName] = author;
        authorAddressToUserName[msg.sender] = userName;
        emit AuthorRegistered(userName, msg.sender, name);
    }
}