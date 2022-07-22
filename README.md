# cNFT - On-chain composable ERC-721

Check out the accompanying [article](https://www.solidnoob.com/blog/on-chain-composable-721) for the background.

The main file is `ERC721C.sol`. This is meant to be a shared contract among other client NFT contracts. Instead of bundling the 721 logic with the contract itself, the client NFT contracts call the already deployed `ERC721C`.
`ERC721C` is just an adapted version of OpenZeppelin's ERC-721 implementation. It was adapted in a way to make it shared.

🔴 This contract has not been thorougly tested so I don't recommend using it in production!!! 🔴

## How to use `ERC721C`

Examples are in the `examples` folder. There are 2 right now: CryptoCoven and InvisibleFriends.
Each example has 2 variants: The original implementation and the "C" variant (that uses `ERC721C`).

## Measuring performance of `ERC721C`

The `tests` folder has tests to measure gas of usage of deploying the original contracts compared to their "C" variant. It also has functions to measure `mint`, `transfer`. `approve`, and `setApprovalForAll` functions.
Here is a table of results:

![table of gas usage comparison](https://res.cloudinary.com/inversia/image/upload/v1658493270/cNFT/gas-usage_evwwov.png)

Essentially `ERC721C` reduces deploy cost at the cost of transactions. This is not ideal, so it definitely needs improvement. See my [article](https://www.solidnoob.com/blog/on-chain-composable-721) for my future plans.
