// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interfaces/IERC721C.sol";
import "../src/examples/CryptoCoven/CryptoCoven.sol";

contract User is IERC721Receiver {
    CryptoCoven private immutable cryptoCoven;

    constructor(CryptoCoven _cryptoCoven) {
        cryptoCoven = _cryptoCoven;
    }

    function mint(uint256 numberOfTokens) public payable {
        cryptoCoven.mint{value: msg.value}(numberOfTokens);
    }

    function safeTransferFrom(address to) public {
        cryptoCoven.safeTransferFrom(
            address(this),
            to,
            /* tokenId= */
            1
        );
    }

    function approve(address to) public {
        cryptoCoven.approve(
            to,
            /* tokenId= */
            1
        );
    }

    function setApprovalForAll(address operator) public {
        cryptoCoven.setApprovalForAll(
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

contract CryptoCovenTest is Test {
    CryptoCoven private cryptoCoven;
    User private user;

    function setUp() public {
        cryptoCoven = new CryptoCoven(
            /* openSeaProxyRegistryAddress= */
            0x5180db8F5c931aaE63c74266b211F580155ecac8,
            /* maxWitches= */
            9999,
            /* maxCommunitySaleWitches= */
            3333,
            /* maxGiftedWitches= */
            250
        );
        cryptoCoven.setIsPublicSaleActive(true);
        user = new User(cryptoCoven);
        // mint one token that will be used for transfer
        user.mint{value: 0.07 ether}(1);
    }

    function testDeploy(address _openSeaProxyRegistryAddress) public {
        new CryptoCoven(
            _openSeaProxyRegistryAddress,
            /* maxWitches= */
            9999,
            /* maxCommunitySaleWitches= */
            3333,
            /* maxGiftedWitches= */
            250
        );
    }

    function testMint() public {
        uint256 numberOfTokens = 2;
        user.mint{value: numberOfTokens * 0.07 ether}(numberOfTokens);
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
