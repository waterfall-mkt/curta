# Notes to deploy Curta

## Setup

1. Set environment variables

- `PRIVATE_KEY`: The private key with enough funds to deploy all contracts necessary. 

- `CURTA_PRIVATE_KEY`: Very important: must be a private key that has never deployed any contracts. We will use the public key of this wallet to compute the Curta contract address.

## Commands

### Anvil Testnet

`PRIVATE_KEY` should be set to the testnet default funded account with public key `0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266`.

```bash
forge script script/Curta.s.sol --rpc-url https://anviltestnet-test.up.railway.app/ --broadcast --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

### Constellation

```bash
forge script script/Curta.s.sol --rpc-url https://waterfall.constellationchain.xyz/http --broadcast --legacy --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```
