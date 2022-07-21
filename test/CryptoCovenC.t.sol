// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/examples/CryptoCovenC/CryptoCovenC.sol";
import "../src/interfaces/IERC721C.sol";

contract CryptoCovenCTest is Test {
    function setUp() public {}

    function testCryptoCovenCDeploy(
        address composableERC721,
        address openSeaProxyRegistryAddress
    ) public {
        new CryptoCovenC(
            IERC721C(composableERC721),
            openSeaProxyRegistryAddress,
            /* maxWitches= */
            9999,
            /* maxCommunitySaleWitches= */
            3333,
            /* maxGiftedWitches= */
            250
        );
    }
}
