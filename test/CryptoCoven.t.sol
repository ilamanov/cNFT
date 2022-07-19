// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/examples/CryptoCoven/contracts/CryptoCoven.sol";

contract CryptoCovenTest is Test {
    function setUp() public {}

    function testExample() public {
        assertTrue(true);
    }

    function testCryptoCovenDeploy(address openSeaProxyRegistryAddress) public {
        new CryptoCoven(
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
