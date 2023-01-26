// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "../../../access/Ownable.sol";

contract ERC721Metadata is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Base URI
    string private baseURI;
    string public baseExtension = ".json";

    bool public revealed = false;
    string public notRevealedUri;
    uint256 private _maxNftSupply;
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory notRevealedUri_,
        uint256 maxNftSupply_
    ) ERC721(name_, symbol_) {
        setBaseURI(baseURI_);
        setNotRevealedURI(notRevealedUri_);
        _maxNftSupply = maxNftSupply_;
    }

    function setBaseURI(string memory baseURI_)
        private onlyOwner {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
            keccak256(abi.encodePacked((baseURI_))),
            "ERC721Metadata: existed baseURI"
        );
        baseURI = baseURI_;
    }

    function reveal()
        external onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        private onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public view override returns (string memory) {
        require(
            tokenId <= _maxNftSupply,
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!_exists(tokenId) || !revealed) {
            return notRevealedUri;
        }

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
            : "";
        }
}