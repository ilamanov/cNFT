//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.4;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC2981.sol";
import "../interfaces/IERC20.sol";

import "../extendable/Ownable.sol";
import "../extendable/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CryptoCoven is IERC721, IERC165, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // ============ MAX LIMITS ============    
    
    uint256 public constant MAX_WITCHES_PER_WALLET = 3;
    uint256 public constant PUBLIC_SALE_PRICE = 0.07 ether;
    uint256 public constant COMMUNITY_SALE_PRICE = 0.05 ether;
    uint256 public immutable maxWitches;
    uint256 public immutable maxGiftedWitches;
    uint256 public immutable maxCommunitySaleWitches;
    
    constructor(
        address _openSeaProxyRegistryAddress,
        uint256 _maxWitches,
        uint256 _maxCommunitySaleWitches,
        uint256 _maxGiftedWitches
    ) ERC721("Crypto Coven", "WITCH") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxWitches = _maxWitches;
        maxCommunitySaleWitches = _maxCommunitySaleWitches;
        maxGiftedWitches = _maxGiftedWitches;
    }
    
    modifier maxWitchesPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_WITCHES_PER_WALLET,
            "Max witches to mint is three"
        );
        _;
    }

    modifier canMintWitches(uint256 numberOfTokens) {
        require(
            tokenCounter + numberOfTokens <= maxWitches - maxGiftedWitches,
            "Not enough witches remaining to mint"
        );
        _;
    }

    modifier canGiftWitches(uint256 num) {
        require(
            numGiftedWitches + num <= maxGiftedWitches,
            "Not enough witches remaining to gift"
        );
        require(
            tokenCounter + num <= maxWitches,
            "Not enough witches remaining to mint"
        );
        _;
    }
    
    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }
    
    // ============ SALE STATE ============

    bool public isPublicSaleActive;
    bool public isCommunitySaleActive;
    
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }
    
    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }
    
    // ============ ALLOWLISTS ============

    bytes32 public communitySaleMerkleRoot;
    bytes32 public claimListMerkleRoot;
    
    function setCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = merkleRoot;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }
    
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
    
    // ============ TRACKERS ============

    uint256 private tokenCounter;
    uint256 public numGiftedWitches;
    
    function getLastTokenId() external view returns (uint256) {
        return tokenCounter;
    }
    
    function nextTokenId() private returns (uint256) {
        unchecked {
            tokenCounter++;
        }
        return tokenCounter;
    }
    
    // ============ GASLESS OS LISTING ============
    
    address private immutable openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;
    
    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }
    
    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    
    // ============ TOKEN URI ============
    
    string private baseURI;
    
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }
    
    // ============ VERIFICATION HASH ============
    
    string public verificationHash;
    
    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
    }
    
    // ============ WITHDRAWALS ============
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    
    // ============ MINTING ============
    
    mapping(address => uint256) public communityMintCounts;
    mapping(address => bool) public claimed;

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintWitches(numberOfTokens)
        maxWitchesPerWallet(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function mintCommunitySale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        communitySaleActive
        canMintWitches(numberOfTokens)
        isCorrectPayment(COMMUNITY_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_WITCHES_PER_WALLET,
            "Max witches to mint in community sale is three"
        );

        require(
            tokenCounter + numberOfTokens <= maxCommunitySaleWitches,
            "Not enough witches remaining to mint"
        );

        communityMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function claim(bytes32[] calldata merkleProof)
        external
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
        canGiftWitches(1)
    {
        require(!claimed[msg.sender], "Witch already claimed by this wallet");

        claimed[msg.sender] = true;

        numGiftedWitches += 1;

        _safeMint(msg.sender, nextTokenId());
    }

    // ============ GIFTING ============

    function reserveForGifting(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canGiftWitches(numToReserve)
    {
        numGiftedWitches += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function giftWitches(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftWitches(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedWitches += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function rollOverWitches(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
    {
        require(
            tokenCounter + addresses.length <= 128,
            "All witches are already rolled over"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            communityMintCounts[addresses[i]] += 1;
            // use mint rather than _safeMint here to reduce gas costs
            // and prevent this from failing in case of grief attempts
            _mint(addresses[i], nextTokenId());
        }
    }

    // ============ ERC165 and ERC2981 ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
