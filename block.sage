# lib/blockchain/block.sage

import crypto.hash as hash

class Block:
    proc init(index, transactions, previous_hash, difficulty):
        self.index = index
        self.timestamp = clock()
        self.transactions = transactions
        self.previous_hash = previous_hash
        self.difficulty = difficulty
        self.nonce = 0
        self.state_root = "0x"
        self.signer = nil
        self.signature = nil
        self.hash = self.calculate_hash()

    proc canonical(value):
        # Deterministic serialization (dict keys sorted, recursion-safe) so
        # hashes are stable across JSON persistence AND sensitive to any
        # in-place modification of transaction content.
        let t = type(value)
        if t == "dict":
            let keys = dict_keys(value)
            # insertion sort for deterministic ordering
            for i in range(1, len(keys)):
                let k = keys[i]
                let j = i - 1
                while j >= 0 and keys[j] > k:
                    keys[j + 1] = keys[j]
                    j = j - 1
                keys[j + 1] = k
            let parts = []
            for k in keys:
                push(parts, str(k) + ":" + self.canonical(value[k]))
            return "{" + join(parts, ",") + "}"
        if t == "array":
            let parts = []
            for v in value:
                push(parts, self.canonical(v))
            return "[" + join(parts, ",") + "]"
        return str(value)

    proc transactions_hash():
        # Tamper-evident commitment to transaction CONTENT (not just count)
        let acc = ""
        for tx in self.transactions:
            acc = acc + hash.sha256_hex(self.canonical(tx))
        return hash.sha256_hex(acc)

    proc calculate_hash():
        let data = str(self.index) + ":" + str(self.timestamp) + ":" + str(self.previous_hash) + ":" + str(self.nonce) + ":" + str(self.state_root) + ":" + self.transactions_hash()
        return hash.sha256_hex(data)

    proc mine():
        let target = ""
        let i = 0
        while i < self.difficulty:
            target = target + "0"
            i = i + 1
        
        while self.hash[:self.difficulty] != target:
            self.nonce = self.nonce + 1
            self.hash = self.calculate_hash()
        
        return self.hash

    proc to_dict():
        let d = {}
        d["index"] = self.index
        d["timestamp"] = self.timestamp
        d["transactions"] = self.transactions
        d["previous_hash"] = self.previous_hash
        d["difficulty"] = self.difficulty
        d["nonce"] = self.nonce
        d["hash"] = self.hash
        d["state_root"] = self.state_root
        d["signer"] = self.signer
        d["signature"] = self.signature
        return d
