<img align="right" width="150" height="150" top="100" src="./assets/curta.png">

# Curta
[**Website**](https://curta.wtf) - [**Docs**](https://curta.wtf/docs) - [**Twitter**](https://twitter.com/curta_ctf)

A CTF protocol, where players create and solve EVM puzzles to earn NFTs.

The goal of players is to view the source code of the puzzle, interpret the code, solve it as if it was a regular puzzle, then verify the solution on-chain. If the solution is valid, a **Flag Token** with the corresponding metadata will be minted to their address.

Since puzzles are on-chain, everyone can view everyone else's submissions. The generative aspect prevents front-running and allows for multiple winners: even if players view someone else's solution, they still have to figure out what the rules/constraints of the puzzle are and apply the solution to their respective starting position.

## Deployments

<table>
    <thead>
        <tr>
            <th>Chain</th>
            <th>Chain ID</th>
            <th>Contract</th>
            <th>v0.0.1</th>
            <th>v0.0.2</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan="3">Mainnet</td>
            <td rowspan="3">1</td>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/2d5de33e3e08ff478ad9e33b6a6f00f819224122/src/Curta.sol">Curta</a></code></td>
            <td><code><a href="https://etherscan.io/address/0x0000000006bC8D9e5e9d436217B88De704a9F307">0x0000000006bC8D9e5e9d436217B88De704a9F307</code></td>
            <td>N/A</td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/2d5de33e3e08ff478ad9e33b6a6f00f819224122/src/AuthorshipToken.sol">AuthorshipToken</a></code></td>
            <td><code><a href="https://etherscan.io/address/0xC0ffeEb30F5aAA18Cd0a799F6dA1bdcb46f63C44">0xC0ffeEb30F5aAA18Cd0a799F6dA1bdcb46f63C44</code></td>
            <td>N/A</td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/2d5de33e3e08ff478ad9e33b6a6f00f819224122/src/FlagRenderer.sol">FlagRenderer</a></code></td>
            <td><code><a href="https://etherscan.io/address/0xf1a9000013303D5641f887C8E1b08D8D60101846">0xf1a9000013303D5641f887C8E1b08D8D60101846</code></td>
            <td>N/A</td>
        </tr>
        <tr>
            <td rowspan="3">Goerli</td>
            <td rowspan="3">5</td>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/2d5de33e3e08ff478ad9e33b6a6f00f819224122/src/Curta.sol">Curta</a></code></td>
            <td><code><a href="https://goerli.etherscan.io/address/0x00000000eCf2b58C296B47caC8C51467c0e307cE">0x00000000eCf2b58C296B47caC8C51467c0e307cE</code></td>
            <td>N/A</td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/2d5de33e3e08ff478ad9e33b6a6f00f819224122/src/AuthorshipToken.sol">AuthorshipToken</a></code></td>
            <td><code><a href="https://goerli.etherscan.io/address/0xC0fFeEe59157d2dd0Ee70d4FABaBCa349b319203">0xC0fFeEe59157d2dd0Ee70d4FABaBCa349b319203</code></td>
            <td>N/A</td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/2d5de33e3e08ff478ad9e33b6a6f00f819224122/src/FlagRenderer.sol">FlagRenderer</a></code></td>
            <td><code><a href="https://goerli.etherscan.io/address/0xf1a9000013303D5641f887C8E1b08D8D60101846">0xf1a9000013303D5641f887C8E1b08D8D60101846</code></td>
            <td>N/A</td>
        </tr>
        <tr>
            <td rowspan="4">Base Mainnet</td>
            <td rowspan="4">8453</td>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/Curta.sol">Curta</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://basescan.org/address/0x00000000D1329c5cd5386091066d49112e590969">0x00000000D1329c5cd5386091066d49112e590969</code></td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/AuthorshipToken.sol">AuthorshipToken</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://basescan.org/address/0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d">0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d</code></td>
        </tr>
            <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/FlagRenderer.sol">FlagRenderer</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://basescan.org/address/0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80">0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80</code></td>
        </tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/TeamRegistry.sol">TeamRegistry</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://basescan.org/address/0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d">0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d</code></td>
        </tr>
        <tr>
            <td rowspan="4">Base Goerli</td>
            <td rowspan="4">84531</td>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/Curta.sol">Curta</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://goerli.basescan.org/address/0x00000000D1329c5cd5386091066d49112e590969">0x00000000D1329c5cd5386091066d49112e590969</code></td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/AuthorshipToken.sol">AuthorshipToken</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://goerli.basescan.org/address/0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d">0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d</code></td>
        </tr>
            <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/FlagRenderer.sol">FlagRenderer</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://goerli.basescan.org/address/0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80">0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80</code></td>
        </tr>
            </tr>
            <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/TeamRegistry.sol">TeamRegistry</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://goerli.basescan.org/address/0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d">0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d</code></td>
        </tr>
        <tr>
            <td rowspan="4">Base Sepolia</td>
            <td rowspan="4">84532</td>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/Curta.sol">Curta</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://sepolia.basescan.org/address/0x00000000D1329c5cd5386091066d49112e590969">0x00000000D1329c5cd5386091066d49112e590969</code></td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/AuthorshipToken.sol">AuthorshipToken</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://sepolia.basescan.org/address/0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d">0xC0FFEE8b8e502403e51f37030E32c52bA4b37f7d</code></td>
        </tr>
            <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/FlagRenderer.sol">FlagRenderer</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://sepolia.basescan.org/address/0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80">0xF1a900007c8b1d6266c186Aa2Ef0eE2e95ffCa80</code></td>
        </tr>
            </tr>
            <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta/blob/main/src/TeamRegistry.sol">TeamRegistry</a></code></td>
            <td>N/A</td>
            <td><code><a href="https://sepolia.basescan.org/address/0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d">0xFacaDE0BCAeBb9B48bd1f613d2fd9B9865A3E61d</code></td>
        </tr>
    </tbody>
<table>

## Usage
This project uses [**Foundry**](https://github.com/foundry-rs/foundry) as its development/testing framework.

### Installation

First, make sure you have Foundry installed. Then, run the following commands to clone the repo and install its dependencies:
```sh
git clone https://github.com/waterfall-mkt/curta.git
cd curta
forge install
```

### Testing
To run tests, run the following command:
```sh
forge test
```

If you'd like to test on a mainnet fork or view a sample [`AuthorshipToken.tokenURI`](https://github.com/waterfall-mkt/curta/blob/main/src/AuthorshipToken.sol) output, run the following command:
```sh
forge test -f mainnet -vvv
```

Alternatively, to test the metadata output, follow the instructions in [`PrintAuthorshipTokenScript`](https://github.com/waterfall-mkt/curta/blob/main/script/PrintAuthorshipToken.s.sol), and run the following command:
```sh
forge script script/PrintAuthorshipToken.s.sol:PrintAuthorshipTokenScript -f mainnet -vvv
```

### Coverage
To view coverage, run the following command:
```sh
forge coverage
```

To generate a report, run the following command:
```sh
forge coverage --report lcov
```

> **Note**
> It may be helpful to use an extension like [**Coverage Gutters**](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) to display the coverage over the code.

### Snapshot
To obtain the same `.gas-snapshot` output as the CI tests, copy [`.env.example`](https://github.com/waterfall-mkt/curta/blob/main/.env.example) into your `.env` file, and run the following command:
```
forge snapshot
```

### Deploying
#### 1. Set environment variables
Create a file named `.env` at the root of the project and copy the contents of `.env.example` into it. Then, fill out each of the variables:
<table>
    <thead>
        <tr>
            <th>Category</th>
            <th>Variable</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan="3">Deploy script configuration</td>
            <td><code>DEPLOYER_PRIVATE_KEY</code></td>
            <td>The account to deploy an instance of <code>FlagRenderer</code> and fund each account below with 0.25 ETH each to deploy the protocol</td>
        </tr>
        <tr>
            <td><code>AUTHORSHIP_TOKEN_PRIVATE_KEY</code></td>
            <td>The account to deploy <code>AuthorshipToken</code></td>
        </tr>
        <tr>
            <td><code>CURTA_PRIVATE_KEY</code></td>
            <td>The account to deploy <code>Curta</code></td>
        </tr>
        <tr>
            <td rowspan="4">RPC endpoints</td>
            <td><code>RPC_URL_GOERLI</code></td>
            <td>An RPC endpoint for Goerli</td>
        </tr>
        <tr>
            <td><code>RPC_URL_MAINNET</code></td>
            <td>An RPC endpoint for mainnet</td>
        </tr>
        <tr>
            <td><code>RPC_URL_BASE_GOERLI</code></td>
            <td>An RPC endpoint for Base Goerli</td>
        </tr>
        <tr>
            <td><code>RPC_URL_BASE_MAINNET</code></td>
            <td>An RPC endpoint for Base mainnet</td>
        </tr>
        <tr>
            <td rowspan="2">API keys</td>
            <td><code>ETHERSCAN_KEY</code></td>
            <td>An <a href="https://etherscan.io" target="_blank" rel="noreferrer noopener"><b>Etherscan</b></a> API key for verifying contracts</td>
        </tr>
        <tr>
            <td><code>BASESCAN_KEY</code></td>
            <td>A <a href="https://basescan.org" target="_blank"
            rel="noreferrer noopener"><b>Basescan</b></a> API key for verifying
            contracts</td>
        </tr>
    </tbody>
<table>

> [!WARNING]
> If accounts specified by `AUTHORSHIP_TOKEN_PRIVATE_KEY` or `CURTA_PRIVATE_KEY` have a nonzero account nonce (i.e. they have sent transactions) or are equal, the deploy script will most likely fail due to incorrect contract address precomputation (the script assumes each account has a nonce of 0).

> [!NOTE]
> The reason the addresses are precomputed are because `AuthorshipToken` and `Curta` must know each other's addresses when being deployed. Also, it allows for vanity addresses :).

#### 2. Run commands to run deploy scripts
If you are deploying to a public chain, replace `DeployMainnet` and `mainnet` with your desired chain and run the following commands:
```sh
forge script script/deploy/DeployMainnet.s.sol:DeployMainnet -f mainnet --broadcast --verify
```

## Acknowledgements
* [**Solmate**](https://github.com/transmissions11/solmate)
* [**Art Gobblers**](https://github.com/artgobblers/art-gobblers)
* [**Foundry Canary**](https://github.com/ZeframLou/foundry-canary)
* [**Shields**](https://shields.build)
