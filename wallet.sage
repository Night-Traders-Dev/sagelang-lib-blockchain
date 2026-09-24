# lib/blockchain/wallet.sage
# Hierarchical Deterministic (HD) Wallet Simulation for SageChain

import crypto.hash as hash
import blockchain.crypto as bc_crypto

class Wallet:
    proc init(mnemonic=nil):
        if not bc_crypto.is_available():
            raise "Secure wallet is unavailable: a verified Ed25519 backend is required"
        if mnemonic != nil:
            let restored = bc_crypto.keypair_from_private(mnemonic)
            self.mnemonic = mnemonic
        else:
            let generated = bc_crypto.generate_keypair()
            self.mnemonic = generated["private"]
        self.seed = nil
        self.addresses = []
        self.derive_address(0)
        self.address = self.addresses[0]["address"]
        self.private_key = self.addresses[0]["private_key"]

    proc generate_mnemonic():
        if self.mnemonic == nil:
            raise "Secure wallet is unavailable: no generated key material"
        return self.mnemonic

    proc derive_address(index):
        if not bc_crypto.is_available():
            raise "Secure wallet is unavailable: a verified Ed25519 backend is required"
        if index != 0:
            raise "HD address derivation is unavailable in the configured crypto backend"
        if len(self.addresses) > 0:
            return self.addresses[0]["address"]
        let keypair = bc_crypto.keypair_from_private(self.mnemonic)
        let priv_key = keypair["private"]
        let pub_key = keypair["public"]
        let addr = "0x" + hash.sha256_hex(pub_key)[:40]
        let w_obj = {}
        w_obj["address"] = addr
        w_obj["private_key"] = priv_key
        w_obj["public_key"] = pub_key
        w_obj["index"] = index
        push(self.addresses, w_obj)
        return addr

    proc get_address():
        return self.addresses[0]["address"]

    proc transaction_message(tx):
        let sender = ""
        let receiver = ""
        let amount = 0.0
        let nonce = 0
        let chain_id = 0
        let tx_type = "transfer"
        let timestamp = 0

        if type(tx) == "dict":
            if dict_has(tx, "sender"):
                sender = tx["sender"]
            if dict_has(tx, "receiver"):
                receiver = tx["receiver"]
            if dict_has(tx, "amount"):
                amount = tx["amount"]
            if dict_has(tx, "nonce"):
                nonce = tx["nonce"]
            if dict_has(tx, "chain_id"):
                chain_id = tx["chain_id"]
            if dict_has(tx, "type"):
                tx_type = tx["type"]
            if dict_has(tx, "timestamp"):
                timestamp = tx["timestamp"]
        else:
            sender = tx.sender
            receiver = tx.receiver
            amount = tx.amount
            nonce = tx.nonce
            chain_id = tx.chain_id
            if hasattr(tx, "type"):
                tx_type = tx.type
            timestamp = tx.timestamp

        return str(sender) + ":" + str(receiver) + ":" + str(amount) + ":" + str(nonce) + ":" + str(chain_id) + ":" + str(tx_type) + ":" + str(timestamp)

    proc sign_transaction(tx):
        let is_dict = type(tx) == "dict"
        let tx_dict = tx
        if not is_dict and hasattr(tx, "to_dict"):
            tx_dict = tx.to_dict()

        let tx_sender = tx_dict["sender"]
        let msg = self.transaction_message(tx_dict)
        if tx_sender != self.address:
            print "Error: Wallet does not own sender address " + tx_sender
            return
        let priv = self.private_key
        let pub = self.addresses[0]["public_key"]
        let signature = bc_crypto.sign(msg, priv)
        if is_dict:
            tx_dict["signature"] = signature
            tx_dict["public_key"] = pub
        else:
            tx.signature = signature
            tx.public_key = pub
