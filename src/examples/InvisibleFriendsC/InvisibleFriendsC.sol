// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                              ..............               ascii art by community member
                        ..::....          ....::..                           rqueue#4071
                    ..::..                        ::..
                  ::..                              ..--..
                ::..                  ....::..............::::..
              ::                ..::::..                      ..::..
            ....            ::::..                                ::::
            ..        ..::..                                        ..::
          ::      ..::..                                              ....
        ....  ..::::                                                    ::
        ::  ..  ..                                                        ::
        ....    ::                                ....::::::::::..        ::
        --::......                    ..::==--::::....          ..::..    ....
      ::::  ..                  ..--..  ==@@++                      ::      ..
      ::                    ..------      ++..                        ..    ..
    ::                  ..::--------::  ::..    ::------..            ::::==++--..
  ....                ::----------------    ..**%%##****##==        --######++**##==
  ..              ::----------------..    ..####++..    --**++    ::####++::    --##==
....          ..----------------..        **##**          --##--::**##++..        --##::
..        ..--------------++==----------**####--          ..**++..::##++----::::::::****
..    ::==------------++##############%%######..            ++**    **++++++------==**##
::  ::------------++**::..............::**####..            ++**..::##..          ..++##
::....::--------++##..                  ::####::          ::****++####..          ..**++
..::  ::--==--==%%--                      **##++        ..--##++::####==          --##--
  ::..::----  ::==                        --####--..    ::**##..  ==%%##::      ::****
  ::      ::                                **####++--==####::      **%%##==--==####::
    ::    ..::..                    ....::::..--########++..          ==**######++..
      ::      ..::::::::::::::::::....      ..::::....                    ....
        ::::..                      ....::....
            ..::::::::::::::::::::....

 */

import "../../extendable/ERC721.sol";
import "../../interfaces/IERC721C.sol";
import "../../interfaces/IERC721Metadata.sol";
import "../../interfaces/IERC2981.sol";

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./@openzeppelin/contracts/utils/Strings.sol";

contract InvisibleFriendsC is
    ERC721,
    IERC721Metadata,
    IERC2981,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    // Token name
    string private constant _name = "Invisible Friends";

    // Token symbol
    string private constant _symbol = "INVSBLE";

    string public PROVENANCE_HASH;

    uint256 constant MAX_SUPPLY = 5000;
    uint256 private _currentId;

    string public baseURI;
    string private _contractURI;

    bool public isActive = false;

    uint256 public price = 0.25 ether;

    bytes32 public merkleRoot;
    mapping(address => uint256) private _alreadyMinted;

    address public beneficiary;
    address public royalties;

    constructor(
        IERC721C _composableERC721,
        address _beneficiary,
        address _royalties,
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) ERC721(_composableERC721) {
        beneficiary = _beneficiary;
        royalties = _royalties;
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _baseURI = baseURI;
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : "";
    }

    // Accessors

    function setProvenanceHash(string calldata hash) public onlyOwner {
        PROVENANCE_HASH = hash;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setMerkleProof(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    // Metadata

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    // Minting

    function mintListed(
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 maxAmount
    ) public payable nonReentrant {
        address sender = _msgSender();

        require(isActive, "Sale is closed");
        require(
            amount <= maxAmount - _alreadyMinted[sender],
            "Insufficient mints left"
        );
        require(_verify(merkleProof, sender, maxAmount), "Invalid proof");
        require(msg.value == price * amount, "Incorrect payable amount");

        _alreadyMinted[sender] += amount;
        _internalMint(sender, amount);
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    // Private

    function _internalMint(address to, uint256 amount) private {
        require(
            _currentId + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId, "");
        }
    }

    function _verify(
        bytes32[] calldata merkleProof,
        address sender,
        uint256 maxAmount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(sender, maxAmount.toString())
        );
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 100) * 5;
        return (royalties, royaltyAmount);
    }
}
