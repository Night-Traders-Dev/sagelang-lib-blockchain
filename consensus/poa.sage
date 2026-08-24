# lib/blockchain/consensus/poa.sage
# Proof of Authority: blocks must be sealed (signed) by an authority.

from blockchain.consensus.base import Consensus
import blockchain.block as block_mod
import blockchain.crypto as bc_crypto

class PoAConsensus(Consensus):
    proc init(blockchain, authorities):
        self.blockchain = blockchain
        self.authorities = authorities # List of authorized signer ids
        self.slashed = {} # Track slashed authorities

    proc is_authority(address):
        for auth in self.authorities:
            if auth == address:
                return true
        return false

    proc validate_block(block):
        # Accept raw dicts too (e.g. arriving over p2p)
        if type(block) == "dict":
            block = self.blockchain.to_block(block)
            if block == nil:
                print "PoA Error: malformed block"
                return false

        # Genesis exemption: the genesis block has no authority signature.
        if block.index == 0 or block.previous_hash == "0":
            return true

        let signer = block.signer
        if signer == nil:
            print "PoA Error: Block missing signer"
            return false

        # Check if signer is slashed
        if dict_has(self.slashed, signer):
            print "PoA Error: Signer " + signer + " has been slashed!"
            return false

        if not self.is_authority(signer):
            print "PoA Error: Signer " + signer + " is not an authority"
            return false

        if block.signature == nil:
            print "PoA Error: Block missing signature"
            return false

        # Verify signature of the block hash
        return bc_crypto.verify(block.hash, block.signature, signer)

    proc seal_block(transactions, miner_address):
        # Check if miner is an authority
        if dict_has(self.slashed, miner_address):
            print "PoA Error: Miner is slashed"
            return nil

        if not self.is_authority(miner_address):
            print "PoA Error: Miner is not an authority"
            return nil

        let block_height = len(self.blockchain.chain)
        let prev_hash = "0"
        if block_height > 0:
            prev_hash = self.blockchain.chain[block_height - 1].hash

        let block = block_mod.Block(block_height, transactions, prev_hash, 0)

        # Automatic Slashing for Equivocation (Double Signing):
        # reject if this authority already sealed a block at this height.
        for b in self.blockchain.chain:
            if b.index == block_height and b.signer != nil and b.signer == miner_address:
                print "Equivocation detected! Slashing " + miner_address
                self.slash(miner_address)
                return nil

        # Seal: sign the block hash as the miner identity
        block.signer = miner_address
        block.signature = bc_crypto.sign(block.hash, miner_address)

        return block

    proc slash(address):
        self.slashed[address] = true
        # Remove from authorities
        let new_auths = []
        for a in self.authorities:
            if a != address:
                push(new_auths, a)
        self.authorities = new_auths

    proc add_authority(address):
        # Validator Rotation / Governance
        for a in self.authorities:
            if a == address:
                return
        push(self.authorities, address)

    proc remove_authority(address):
        let new_auths = []
        for a in self.authorities:
            if a != address:
                push(new_auths, a)
        self.authorities = new_auths
