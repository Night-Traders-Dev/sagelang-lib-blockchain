# lib/blockchain/crypto.sage
import ed25519 as native_crypto

proc is_available():
    return native_crypto != nil

proc require_backend():
    if not is_available():
        raise "Secure blockchain crypto is unavailable: a verified Ed25519 backend is required"

proc generate_keypair():
    require_backend()
    let pair = native_crypto.generate_keypair()
    if pair == nil:
        raise "Secure Ed25519 crypto backend returned an invalid key"
    return pair

proc keypair_from_private(private_key):
    require_backend()
    if private_key == nil:
        raise "Secure Ed25519 crypto rejected a nil private key"
    let pair = native_crypto.keypair_from_private(private_key)
    if pair == nil:
        raise "Secure Ed25519 crypto backend returned an invalid key"
    return pair

proc sign(message, private_key):
    require_backend()
    if message == nil or private_key == nil:
        raise "Secure Ed25519 crypto rejected nil signing input"
    let signature = native_crypto.sign(message, private_key)
    if signature == nil:
        raise "Secure Ed25519 crypto backend failed to sign"
    return signature

proc verify(message, signature, public_key):
    require_backend()
    if message == nil or signature == nil or public_key == nil:
        return false
    return native_crypto.verify(message, signature, public_key)
