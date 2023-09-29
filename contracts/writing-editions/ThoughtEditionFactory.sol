// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ThoughtEdition.sol";
import "./IThoughtEdition.sol";
import "../standard/Clones.sol";
import "../standard/Ownable.sol";

contract ThoughtEditionFactory is Ownable {
    address public implementation;

    // Mapping to store the editions published by each author
    mapping(address => address[]) public authorToEditions;

    // Mapping to track used salts
    mapping(bytes32 => bool) public salts;

    // Events
    event CloneDeployed(address indexed factory, address indexed owner, address indexed clone);

    constructor() Ownable(msg.sender) {
        // Set implementation contract.
        implementation = address(new ThoughtEdition(address(this)));
    }

    /// @notice Deploy a new writing edition clone with the sender as the owner.
    /// @param edition edition parameters used to deploy the clone.
    function create(
        IThoughtEdition.ThoughtEdition memory edition
    ) external returns (address clone) {
        clone = deployCloneAndInitialize(msg.sender, edition);
    }

    // Function to create a new blog
    function deployCloneAndInitialize(
        address owner,
        IThoughtEdition.ThoughtEdition memory edition
    ) internal returns (address clone) {
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
    function getAuthorEditionsCount(address author) external view returns (uint256) {
        return authorToEditions[author].length;
    }

    // Function to get the address of a specific edition published by an author
    function getAuthorEdition(address author, uint256 index) external view returns (address) {
        require(index < authorToEditions[author].length, "Index out of range");
        return authorToEditions[author][index];
    }
}