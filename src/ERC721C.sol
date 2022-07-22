// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts (v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./interfaces/IERC721C.sol";
import "./interfaces/IERC721Receiver.sol";

/**
 * @dev On-chain composable ERC-721 implementation. This is
 * a shared contract meant to be used by other NFT contracts (clients).
 * The benefit of using this instead of extending the OZ;s ERC-721 implementation
 * is you get on-chain composition instead of off-chain composition.
 * On-chain composition has lower deploy cost (no need to redeploy the same
 * OZ contracts over and over) at no significant overhead of transactions cost.
 * Another benefit of on-chain composition is that the shared contract needs to be
 * audited only once and all clients can benefit from this one audit (reduced audit costs).
 */
contract ERC721C is IERC721C {
    // ----------- TRACKERS -----------
    // Both trackers have the client contract address as the first key

    // Mapping owner address to token count
    mapping(address => mapping(address => uint256)) private _balances;

    // Mapping from token ID to owner address
    mapping(address => mapping(uint256 => address)) private _owners;

    function balanceOf(address client, address owner)
        external
        view
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[client][owner];
    }

    function ownerOf(address client, uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        address owner = _owners[client][tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    // ----------- TRANSFER FUNCTIONALITY -----------

    function transferFrom(
        address originalSender,
        address from,
        address to,
        uint256 tokenId
    ) public override {
        address owner = _owners[msg.sender][tokenId];
        require(
            owner != address(0),
            "ERC721: operator query for nonexistent token"
        );
        require(
            originalSender == owner ||
                isApprovedForAll[msg.sender][owner][originalSender] ||
                _tokenApprovals[msg.sender][tokenId] == originalSender,
            "ERC721: caller is not token owner nor approved"
        );
        require(owner == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[msg.sender][from] -= 1;
        _balances[msg.sender][to] += 1;
        _owners[msg.sender][tokenId] = to;
    }

    function safeTransferFrom(
        address originalSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external override {
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
        // The neext line checks if "to" address is a contract.
        // This is not a fool proof way of checking whether its a contract.
        // See OpenZeppelin's Address.isContract function for caveats.
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
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     */
    function mint(address to, uint256 tokenId) public override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(
            _owners[msg.sender][tokenId] == address(0),
            "ERC721: token already minted"
        );

        _balances[msg.sender][to] += 1;
        _owners[msg.sender][tokenId] = to;
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
    ) external override {
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
    function burn(uint256 tokenId) external override {
        address owner = _owners[msg.sender][tokenId];
        require(owner != address(0), "ERC721: token does not exist");

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[msg.sender][owner] -= 1;
        delete _owners[msg.sender][tokenId];
    }

    // ----------- APPROVALS -----------
    // Both trackers have the client contract address as the first key

    // Mapping from token ID to approved address
    mapping(address => mapping(uint256 => address)) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => mapping(address => bool)))
        public isApprovedForAll;

    function getApproved(address client, uint256 tokenId)
        external
        view
        override
        returns (address operator)
    {
        require(
            _owners[client][tokenId] != address(0),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[client][tokenId];
    }

    function approve(
        address originalSender,
        address to,
        uint256 tokenId
    ) external override {
        address owner = _owners[msg.sender][tokenId];
        require(to != owner, "ERC721: approval to current owner");
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
        _tokenApprovals[msg.sender][tokenId] = to;
    }

    function setApprovalForAll(
        address originalSender,
        address operator,
        bool approved
    ) external override {
        isApprovedForAll[msg.sender][originalSender][operator] = approved;
    }
}
