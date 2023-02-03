// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./token/ERC721/extensions/ERC721Royalty.sol";
import "./token/ERC721/extensions/ERC721Metadata.sol";
import "./utils/math/SafeMath.sol";

contract ParrotsFromHell is ERC721Metadata, ERC2981 {
    using SafeMath for uint256;
    
    uint256 public constant MAX_NFT_SUPPLY = 666;
    uint256 public constant MINT_PRICE = 10 ether;

    bool public paused = true;
    uint256 public pendingCount = MAX_NFT_SUPPLY;

    mapping(uint256 => address) public minters;
    mapping(address => uint256) public mintedByWallet;

    address[] private _admins;
    uint96 private _feeNumerator;

    uint256 private _totalSupply;
    uint256[667] private _pendingIDs;

    // Giveaway winners
    mapping(uint256 => address) private _giveaways;

    constructor(
        string memory baseURI_,
        string memory notRevealedUri_,
        address[] memory admins_
    ) ERC721Metadata(
        "ParrotsFromHell",
        "PFH",
        baseURI_,
        notRevealedUri_,
        MAX_NFT_SUPPLY
    ){
        _feeNumerator = 100;
        _setDefaultRoyalty(_msgSender(), _feeNumerator);
        _admins = admins_;
    }

    function totalSupply()
        public view override
        returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface (bytes4 interfaceId) 
        public view virtual override(ERC721Enumerable, ERC2981) 
        returns(bool) {
            return super.supportsInterface(interfaceId);
    }

    /// @dev This function collects all the token IDs of a wallet.
    /// @param owner_ This is the address for which the balance of token IDs is returned.
    /// @return an array of token IDs.
    function walletOfOwner(address owner_)
        external view returns (uint256[] memory) {
            uint256 ownerTokenCount = balanceOf(owner_);
            uint256[] memory tokenIDs = new uint256[](ownerTokenCount);
            for (uint256 i = 0; i < ownerTokenCount; i++) {
                tokenIDs[i] = tokenOfOwnerByIndex(owner_, i);
            }
            return tokenIDs;
    }

    /// @dev This function mints NFTs by count.
    /// @param counts_ Counts of NFTs that will be minted.
    function mint(uint256 counts_)
        external payable {
        require(pendingCount > 0, "ParrotsFromHell: All minted");
        require(counts_ > 0, "ParrotsFromHell: Counts cannot be zero");
        require(totalSupply().add(counts_) <= MAX_NFT_SUPPLY,
            "ParrotsFromHell: Sale already ended");
        require(!paused, "ParrotsFromHell: The contract is paused");
        require(MINT_PRICE.mul(counts_) == msg.value,
            "ParrotsFromHell: invalid value");

        for (uint i = 0; i < counts_; i++) {
            uint256 tokenID = _randomMint(_msgSender());
            _manageRoyalty(tokenID, _msgSender(), _feeNumerator);
            _totalSupply += 1;
            _splitBalance(msg.value.div(counts_));
        }
    }

    function _randomMint(address to_)
        private returns (uint256) {
        require(to_ != address(0), "ParrotsFromHell: Zero address!");

        require(totalSupply() < MAX_NFT_SUPPLY,
            "ParrotsFromHell: Max supply reached!");

        uint256 randomIn = _getRandom()
            .mod(pendingCount)
            .add(1);

        uint256 tokenID = _popPendingAtIndex(randomIn);

        minters[tokenID] = to_;
        mintedByWallet[to_] += 1;

        _safeMint(to_, tokenID);

        return tokenID;
    }

    function _manageRoyalty(
        uint256 tokenID_,
        address tokenOwner_,
        uint96 feeNumerator_)
        private {
            uint96 fee = feeNumerator_;
            if(tokenID_ <= 6) {
                fee = 600;
            } else if (tokenID_ <= 100) {
                fee = 200;
            }
            _setTokenRoyalty(tokenID_, tokenOwner_, fee);
    }

    function _splitBalance(uint256 amount_)
        private {    
        uint256 subAmount = amount_.div(_admins.length);

        for (uint i = 0; i < _admins.length; i++) {
            payable(_admins[i]).transfer(subAmount);
        }
    }

    function _popPendingAtIndex(uint256 index_)
        private returns (uint256) {
        uint256 tokenID = _pendingIDs[index_].add(index_);

        if (index_ != pendingCount) {
            uint256 lastPendingID = _pendingIDs[pendingCount]
                .add(pendingCount);
            _pendingIDs[index_] = lastPendingID.sub(index_);
        }

        pendingCount -= 1;
        return tokenID;
    }

    function _getRandom()
        private view returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, pendingCount)
            )
        );
    }

    // onlyOwner

    function pause(bool state_)
        public onlyOwner {
        paused = state_;
    }

    function randomGiveaway(address[] memory winners_)
        external onlyOwner {

        for(uint i = 0; i < winners_.length; i++) {
            uint256 tokenID = _randomMint(winners_[i]);
            _giveaways[tokenID] = winners_[i];
        }

        _totalSupply = _totalSupply
            .add(winners_.length);
    }
}
