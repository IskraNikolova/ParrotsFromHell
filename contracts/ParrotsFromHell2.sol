// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./token/ERC721/extensions/ERC721Royalty.sol";
import "./token/ERC721/extensions/ERC721Metadata.sol";
import "./utils/math/SafeMath.sol";
import "./ParrotsFromHell.sol";

contract ParrotsFromHell2 is ERC721Metadata, ERC2981 {
    using SafeMath for uint256;
    
    uint256 public constant MAX_NFT_SUPPLY = 1332;
    uint256 public constant MINT_PRICE = 5 ether;

    bool public paused = true;
    uint256 public pendingCount = MAX_NFT_SUPPLY;

    mapping(uint256 => address) public minters;
    mapping(address => uint256) public mintedByWallet;
    mapping(address => bool) public dYGAAward;

    ParrotsFromHell private _pfh;
    address[] private _admins;
    uint96 private _feeNumerator;

    uint256 private _totalSupply;
    uint256[1333] private _pendingIDs;
    uint256 private _freeCounts;

    // Giveaway winners
    mapping(uint256 => address) private _giveaways;

    constructor(
        string memory baseURI_,
        string memory notRevealedUri_,
        address[] memory admins_,
        address pfh_
    ) ERC721Metadata(
        "ParrotsFromHell2",
        "PFH2",
        baseURI_,
        notRevealedUri_,
        MAX_NFT_SUPPLY
    ){
        _pfh = ParrotsFromHell(pfh_);
        _freeCounts = MAX_NFT_SUPPLY.sub(666);
        _feeNumerator = 200;
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
        require(_freeCounts > 0, "ParrotsFromHell 2: All minted");
        require(counts_ > 0, "ParrotsFromHell 2: Counts cannot be zero");
        require(totalSupply().add(counts_) <= MAX_NFT_SUPPLY,
            "ParrotsFromHell 2: Sale already ended");
        require(!paused, "ParrotsFromHell 2: The contract is paused");
        require(MINT_PRICE.mul(counts_) == msg.value,
            "ParrotsFromHell 2: invalid value");

        for (uint i = 0; i < counts_; i++) {
            uint256 tokenID = _randomMint(_msgSender());
            _manageRoyalty(tokenID, _msgSender(), _feeNumerator);
            _totalSupply += 1;
            _splitBalance(msg.value.div(counts_));
        }

        _freeCounts = _freeCounts.sub(counts_);
    }

    /// @dev This function mints NFTs free for minters from first contract.
    function mintFree()
        external payable {
        require(dYGAAward[_msgSender()], 
            "ParrotsFromHell 2: You haven't permission for free mint");
        require(_pfh.balanceOf(_msgSender()) > 0, 
            "ParrotsFromHell 2: You haven't permission for free mint");    
        require(totalSupply().add(1) <= MAX_NFT_SUPPLY,
            "ParrotsFromHell 2: Sale already ended");

        uint256 counts_ = _pfh.balanceOf(_msgSender());
        for (uint256 i = 0; i < counts_; i++) {
            uint256 tokenID = _randomMint(_msgSender());
            _manageRoyalty(tokenID, _msgSender(), _feeNumerator);
            _totalSupply += 1;
        }

        dYGAAward[_msgSender()] = true;
    }

    function _randomMint(address to_)
        private returns (uint256) {
        require(to_ != address(0), "ParrotsFromHell 2: Zero address!");

        require(totalSupply() < MAX_NFT_SUPPLY,
            "ParrotsFromHell 2: Max supply reached!");

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
                fee = 800;
            } else if (tokenID_ <= 100) {
                fee = 400;
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
