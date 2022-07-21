// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721C.sol";

/**
 * @dev Extendable ERC721 contract that delegates
 * all work to the Composable ERC721
 */
contract ERC721 is IERC721, IERC165 {
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
        return composableERC721.balanceOf(address(this), owner);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return composableERC721.ownerOf(address(this), tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        address oldOwner = ownerOf(tokenId);
        composableERC721.transferFrom(msg.sender, from, to, tokenId);
        emit Approval(oldOwner, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        address oldOwner = ownerOf(tokenId);
        composableERC721.safeTransferFrom(msg.sender, from, to, tokenId, _data);
        emit Approval(oldOwner, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
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

    function approve(address to, uint256 tokenId) public virtual override {
        composableERC721.approve(msg.sender, to, tokenId);
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override
    {
        composableERC721.setApprovalForAll(msg.sender, operator, _approved);
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        composableERC721.safeMint(msg.sender, to, tokenId, _data);
        emit Transfer(address(0), to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        composableERC721.mint(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address oldOwner = ownerOf(tokenId);
        composableERC721.burn(tokenId);
        emit Approval(oldOwner, address(0), tokenId);
        emit Transfer(oldOwner, address(0), tokenId);
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
