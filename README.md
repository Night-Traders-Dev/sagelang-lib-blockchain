# blockchain

## Purpose
Core blockchain development framework for SageLang. Provides primitives for building decentralized applications, contracts, and custom chains.

## Features
- **Consensus**: PoW and PoA consensus engines.
- **Smart Contracts**: Contract definition, transaction, and state management.
- **Storage**: Merkle trees, wallet management, and blockchain database (db).

## Usage Example
```sage
import blockchain.blockchain
import blockchain.transaction

let chain = Blockchain("mainnet")
let tx = Transaction(sender, receiver, amount)
chain.add_transaction(tx)
```
