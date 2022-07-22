// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interfaces/IERC721C.sol";
import "../src/examples/InvisibleFriends/InvisibleFriends.sol";

contract User is IERC721Receiver {
    InvisibleFriends private immutable invisibleFriends;

    constructor(InvisibleFriends _invisibleFriends) {
        invisibleFriends = _invisibleFriends;
    }

    function mint(uint256 numberOfTokens) public payable {
        invisibleFriends.mintListed{value: msg.value}(numberOfTokens, 5);
    }

    function safeTransferFrom(address to) public {
        invisibleFriends.safeTransferFrom(
            address(this),
            to,
            /* tokenId= */
            1
        );
    }

    function approve(address to) public {
        invisibleFriends.approve(
            to,
            /* tokenId= */
            1
        );
    }

    function setApprovalForAll(address operator) public {
        invisibleFriends.setApprovalForAll(
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

contract InvisibleFriendsTest is Test {
    InvisibleFriends private invisibleFriends;
    User private user;

    function setUp() public {
        invisibleFriends = new InvisibleFriends(
            0x5180db8F5c931aaE63c74266b211F580155ecac8,
            0x5180db8F5c931aaE63c74266b211F580155ecac8,
            "baseUri",
            "contractUri"
        );
        invisibleFriends.setActive(true);
        user = new User(invisibleFriends);
        // mint one token that will be used for transfer
        user.mint{value: 0.25 ether}(1);
    }

    function testDeploy(address beneficiary, address royalties) public {
        new InvisibleFriends(beneficiary, royalties, "baseUri", "contractUri");
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
