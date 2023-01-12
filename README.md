# Curta

An extensible CTF, where each part is a generative puzzle, and each solution is minted as an NFT.

# Notes to deploy Curta

## Setup

1. Set environment variables

- `PRIVATE_KEY`: The private key with enough funds to deploy all contracts necessary. 

- `CURTA_PRIVATE_KEY`: Very important: must be a private key that has never deployed any contracts. We will use the public key of this wallet to compute the Curta contract address.

- `AUTHORSHIP_TOKEN_PRIVATE_KEY`: the private key of the wallet you want to use as the deployer of AuthorshipToken contract.

## Commands

### Constellation for Testing

```bash
forge script script/deploy/DeployTest.s.sol --rpc-url https://waterfall.constellationchain.xyz/http --broadcast --legacy --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

