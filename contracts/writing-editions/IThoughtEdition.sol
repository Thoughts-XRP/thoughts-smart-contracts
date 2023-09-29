// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IThoughtEdition {
    struct ThoughtEdition {
        string title;
        string description;
        string imageURI;
        string contentURI;
        uint256 price;
    }

    event ThoughtEditionPurchased(address indexed clone, uint256 tokenId, address indexed recipient, uint256 price);

    function initialize(address _owner, ThoughtEdition memory edition) external;
    function safeMint(address to) external;
    function purchase() external payable;
    function setBaseURI(string memory uri) external;
    function getContentURI() external view returns (string memory);
    function getEdition() external view returns (ThoughtEdition memory);
}