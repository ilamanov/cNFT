// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC721C.sol";
import "../src/interfaces/IERC721C.sol";
import "../src/interfaces/IERC721Receiver.sol";
import "../src/examples/InvisibleFriendsC/InvisibleFriendsC.sol";

contract User is IERC721Receiver {
    InvisibleFriendsC private immutable invisibleFriendsC;

    constructor(InvisibleFriendsC _invisibleFriendsC) {
        invisibleFriendsC = _invisibleFriendsC;
    }

    function mint(uint256 numberOfTokens) public payable {
        invisibleFriendsC.mintListed{value: msg.value}(numberOfTokens, 5);
    }

    function safeTransferFrom(address to) public {
        invisibleFriendsC.safeTransferFrom(
            address(this),
            to,
            /* tokenId= */
            1
        );
    }

    function approve(address to) public {
        invisibleFriendsC.approve(
            to,
            /* tokenId= */
            1
        );
    }

    function setApprovalForAll(address operator) public {
        invisibleFriendsC.setApprovalForAll(
            operator,
            /* approved= */
            true
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract CryptoCovenCTest is Test {
    ERC721C private composableERC721;
    InvisibleFriendsC private invisibleFriendsC;
    User private user;

    function setUp() public {
        composableERC721 = new ERC721C();
        invisibleFriendsC = new InvisibleFriendsC(
            IERC721C(composableERC721),
            0x5180db8F5c931aaE63c74266b211F580155ecac8,
            0x5180db8F5c931aaE63c74266b211F580155ecac8,
            "baseUri",
            "contractUri"
        );
        invisibleFriendsC.setActive(true);
        user = new User(invisibleFriendsC);
        // mint one token that will be used for transfer
        user.mint{value: 0.25 ether}(1);
    }

    function testDeploy(
        address _composableERC721,
        address beneficiary,
        address royalties
    ) public {
        new InvisibleFriendsC(
            IERC721C(_composableERC721),
            beneficiary,
            royalties,
            "baseUri",
            "contractUri"
        );
    }

    function testMint() public {
        uint256 numberOfTokens = 2;
        user.mint{value: numberOfTokens * 0.25 ether}(numberOfTokens);
    }

    function testTransfer(address to) public {
        vm.assume(to > address(0));
        user.safeTransferFrom(to);
    }

    function testApprove(address to) public {
        vm.assume(to > address(0));
        user.approve(to);
    }

    function testSetApprovalForAll(address operator) public {
        vm.assume(operator > address(0));
        user.setApprovalForAll(operator);
    }
}
