// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../standard/ERC721.sol";
import "../standard/ERC721Enumerable.sol";
import "../standard/ERC721Burnable.sol";
import "../standard/Ownable.sol";
import "../standard/Base64.sol";
import "../standard/Counters.sol";
import "./IThoughtEdition.sol";

contract ThoughtEdition is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, IThoughtEdition {

    /// @notice Address that deploys and initializes clones.
    address public immutable factory;

    /// > [[[[[[[[[[[ Token Data ]]]]]]]]]]]
    /// @notice Token title.
    string public title;

    /// @notice Token description.
    string public description;

    /// @notice Token text content, stored in IPFS.
    string private contentURI;

    /// @notice Token image content, stored in IPFS.
    string public imageURI;

    /// @notice Token price, set by the owner.
    uint256 public price;

    /// @notice Base URI for metadata.
    string internal baseMetadataURI;

    /// @notice Implementation logic for clones.
    /// @param _factory the factory contract deploying clones with this implementation.
    constructor(address _factory, string memory _baseMetadataURI) ERC721("ThoughtEdition", "THT") Ownable(address(0)) {
        // Assert not the zero-address.
        require(_factory != address(0), "must set factory");

        // Store factory.
        factory = _factory;
        // Store baseURI
        baseMetadataURI = _baseMetadataURI;
    }

    /// @notice Initialize a clone by storing edition parameters. Called only by the factory. 
    /// @param _owner owner of the clone.
    /// @param edition edition parameters used to deploy the clone.
    function initialize(address _owner, ThoughtEdition memory edition) override external {
        // Only factory can call this function.
        require(msg.sender == factory, "unauthorized caller");

        // Store edition data.
        title = edition.title;
        description = edition.description;
        imageURI = edition.imageURI;
        contentURI = edition.contentURI;
        price = edition.price;
        
        // Store owner.
        _setInitialOwner(_owner);
    }

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    function safeMint(address to) override external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function purchase() override external payable {
        require(msg.value == price, "Incorrect funds to buy this edition");
        require(balanceOf(msg.sender) == 0, "Sender have already purchased this edition");
        payable(owner).transfer(msg.value);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        emit ThoughtEditionPurchased(msg.sender, tokenId, msg.sender, price);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
   
    function getContentURI() override external view returns (string memory) {
        if (price == 0 || balanceOf(msg.sender) > 0 || isOwner()) return contentURI;
        return  "";
    }

    /// @notice Get `tokenId` URI or data
    /// @param tokenId The tokenId used to request data
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: query for nonexistent token");
         string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', _escapeQuotes(title)," ", Strings.toString(tokenId),
                        '", "description": "', _escapeQuotes(description),
                        '", "content": ', contentURI,
                        '", "external_url": ', getExternalURL(tokenId),
                        '", "image": ', imageURI,
                        '", "attributes":[{ "trait_type": "Edition Serial", "value": ',
                        Strings.toString(tokenId),
                        "}] }"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @notice External Url.
    function getExternalURL(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, "/", _addressToString(address(this)), "/", Strings.toString(tokenId)));
    }

    // @notice Get Edition details
    function getEdition() external view override returns (ThoughtEdition memory) {
        string memory _contentURI = "";
        if (price == 0 || balanceOf(msg.sender) > 0 || isOwner()) {
            _contentURI = contentURI;
        } 
        return ThoughtEdition({
            title: title,
            description: description,
            imageURI: imageURI,
            contentURI: _contentURI,
            price: price
        });
    }

    function setBaseURI(string memory uri) external override onlyOwner {
        baseMetadataURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseMetadataURI;
    }

    function _escapeQuotes(
        string memory str
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(
                strBytes.length + (quotesCount)
            );
            uint256 index;
            for (uint8 i = 0; i < strBytes.length; i++) {
                if (strBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = strBytes[i];
            }
            return string(escapedBytes);
        }
        return str;
    }

    // https://ethereum.stackexchange.com/questions/8346/convert-address-to-string/8447#8447
    function _addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}