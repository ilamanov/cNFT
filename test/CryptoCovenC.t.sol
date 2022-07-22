// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC721C.sol";
import "../src/interfaces/IERC721C.sol";
import "../src/interfaces/IERC721Receiver.sol";
import "../src/examples/CryptoCovenC/CryptoCovenC.sol";

contract User is IERC721Receiver {
    CryptoCovenC private immutable cryptoCovenC;

    constructor(CryptoCovenC _cryptoCovenC) {
        cryptoCovenC = _cryptoCovenC;
    }

    function mint(uint256 numberOfTokens) public payable {
        cryptoCovenC.mint{value: msg.value}(numberOfTokens);
    }

    function safeTransferFrom(address to) public {
        cryptoCovenC.safeTransferFrom(
            address(this),
            to,
            /* tokenId= */
            1
        );
    }

    function approve(address to) public {
        cryptoCovenC.approve(
            to,
            /* tokenId= */
            1
        );
    }

    function setApprovalForAll(address operator) public {
        cryptoCovenC.setApprovalForAll(
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
    CryptoCovenC private cryptoCovenC;
    User private user;

    function setUp() public {
        composableERC721 = new ERC721C();
        cryptoCovenC = new CryptoCovenC(
            IERC721C(composableERC721),
            /* openSeaProxyRegistryAddress= */
            0x5180db8F5c931aaE63c74266b211F580155ecac8,
            /* maxWitches= */
            9999,
            /* maxCommunitySaleWitches= */
            3333,
            /* maxGiftedWitches= */
            250
        );
        cryptoCovenC.setIsPublicSaleActive(true);
        user = new User(cryptoCovenC);
        // mint one token that will be used for transfer
        user.mint{value: 0.07 ether}(1);
    }

    function testDeploy(
        address _composableERC721,
        address _openSeaProxyRegistryAddress
    ) public {
        new CryptoCovenC(
            IERC721C(_composableERC721),
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
