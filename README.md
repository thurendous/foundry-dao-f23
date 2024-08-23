# Summary

1. We are going to have a contract controlled by a DAO.
2. Every transaction that the DAO wants to send has to be voted on.
3. We will use ERC20 tokens for voting (Bad model, please research better models as you get better!)

The standard process of how to call a DAO system is recorded in the test: testGovernanceUpdateBox. The process is as follows:

- There is something we want to call in the contract.
  - we want to update the value in box contract.
- We create a proposal about the call including some descriptions.
  - `uint256 proposalId = governor.propose(targets, values, calldatas, description);`
- after a while
  - `vm.warp` timestamp and `vm.roll` block number
- We vote on the proposal
  - `governor.castVoteWithReason(proposalId, 1, reason);`
- after a while
  - `vm.warp` timestamp and `vm.roll` block number
- We queue the proposal
  - `governor.queue(proposalId);`
- after a while
  - `vm.warp` timestamp and `vm.roll` block number
- We execute the proposal
  - `governor.execute(proposalId);`
- The value is updated in the contract.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
