// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721C.sol";

/**
 * @dev TODO
 */
contract ERC721 is IERC165, IERC721 {
    IERC721C private immutable composableERC721;

    constructor(IERC721C _composableERC721) {
        composableERC721 = _composableERC721;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return composableERC721.balanceOf(msg.sender, owner);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return composableERC721.ownerOf(msg.sender, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        composableERC721.safeTransferFrom(msg.sender, from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        composableERC721.safeTransferFrom(msg.sender, from, to, tokenId, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        composableERC721.transferFrom(msg.sender, from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        composableERC721.approve(msg.sender, to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override
    {
        composableERC721.setApprovalForAll(msg.sender, operator, _approved);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address operator)
    {
        return composableERC721.getApproved(address(this), tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            composableERC721.isApprovedForAll(address(this), owner, operator);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        composableERC721.safeMint(msg.sender, to, tokenId, _data);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        composableERC721.mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        composableERC721.burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
