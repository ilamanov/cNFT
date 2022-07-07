// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts (v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./interfaces/IERC721Receiver.sol";

/**
 * @dev TODO
 */
contract ERC721C {
    // ----------- TRACKERS -----------
    // Both trackers have the client contract address as the first key

    // Mapping owner address to token count
    mapping(address => mapping(address => uint256)) public balanceOf;

    // Mapping from token ID to owner address
    mapping(address => mapping(uint256 => address)) public ownerOf;

    // ----------- TRANSFER FUNCTIONALITY -----------

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address originalSender,
        address from,
        address to,
        uint256 tokenId
    ) public {
        // TODO ALSO ADD to gas optimization, is it better to create clientContract=msg.sneder and reuse the var?
        // TODO how to create a scope so that only msg.sender's stuff is viisble?
        // TODO how is it better to access? throufh storage read or through this.getter?
        address owner = ownerOf[msg.sender][tokenId];
        require(
            originalSender == owner ||
                isApprovedForAll[msg.sender][owner][originalSender] ||
                getApproved[msg.sender][tokenId] == originalSender,
            "ERC721: caller is not token owner nor approved"
        );
        require(owner == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        balanceOf[msg.sender][from] -= 1;
        balanceOf[msg.sender][to] += 1;
        ownerOf[msg.sender][tokenId] = to;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address originalSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        transferFrom(originalSender, from, to, tokenId);
        require(
            _checkOnERC721Received(originalSender, from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address originalSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        // next line check if "to" address is a contract. this is not a fool proof way of checking whether its a contract. check OZ's address contract for caveats. TODO insert the comments in-line here
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    originalSender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // ----------- MINT/BURN FUNCTIONALITY -----------

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     */
    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "ERC721: mint to the zero address");
        require(
            ownerOf[msg.sender][tokenId] == address(0),
            "ERC721: token already minted"
        );

        balanceOf[msg.sender][to] += 1;
        ownerOf[msg.sender][tokenId] = to;
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     */
    function safeMint(
        address originalSender,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        mint(to, tokenId);
        require(
            _checkOnERC721Received(
                originalSender,
                address(0),
                to,
                tokenId,
                data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function burn(uint256 tokenId) public {
        address owner = ownerOf[msg.sender][tokenId];

        // Clear approvals
        _approve(address(0), tokenId);

        balanceOf[msg.sender][owner] -= 1;
        delete ownerOf[msg.sender][tokenId];

        // TODO: this and mint function might need sanity checks like who is allowed to burn or mint this token. but since the caller will be modifying only their own storage, might not be nevessary. maybe actually many of the require statements are not actuall mecessary
        // TODO: do i need exists check here?
    }

    // ----------- APPROVALS -----------
    // Both trackers have the client contract address as the first key

    // Mapping from token ID to approved address
    mapping(address => mapping(uint256 => address)) public getApproved;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => mapping(address => bool)))
        public isApprovedForAll;

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
        address originalSender,
        address to,
        uint256 tokenId
    ) public {
        address owner = ERC721C.ownerOf[msg.sender][tokenId];
        require(
            originalSender == owner ||
                isApprovedForAll[msg.sender][owner][originalSender],
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Approve without doing any additional checks
     */
    function _approve(address to, uint256 tokenId) private {
        // TODO check if msg.semder is correct here
        getApproved[msg.sender][tokenId] = to;
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address originalSender,
        address operator,
        bool approved
    ) public {
        isApprovedForAll[msg.sender][originalSender][operator] = approved;
    }
}
