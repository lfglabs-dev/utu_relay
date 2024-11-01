# Utu Relay

Utu Relay is a Starknet smart contract that enables secure verification of Bitcoin transactions and events. Named after the ancient Sumerian sun god who was believed to see everything that happened in the world, Utu Relay aims to provide a transparent and secure way to bridge Bitcoin data to the Starknet ecosystem.

## Overview

Utu Relay allows anyone to register Bitcoin block headers on Starknet and set the canonical chain. Smart contracts can access these blocks, along with trust metrics like cumulative proof-of-work and unchallenged time, to verify that any Bitcoin transaction was accepted by the network.

Key features:
- Verify any part of Bitcoin's history
- Maintain canonical chain
- Strong security guarantees
- Game theory incentives for maintaining accuracy

## Security Guarantees

- Accurate proof-of-work verification and reporting
- Accurate block height verification through coinbase transaction proofs
- Strongest proof-of-work chain selection
- On-chain detection of potential chain reorganizations
- Configurable PoW thresholds for enhanced security

## Contract Interface

### register_blocks(blocks: Span<BlockHeader>)

Register a list of Bitcoin block headers. Blocks don't need to be contiguous or in order. Each block must meet the configured proof-of-work threshold to be accepted.

### update_canonical_chain(begin_height: u64, end_height: u64, end_block_hash: Digest, height_proof: Option<HeightProof>)

Set the official canonical chain for a given interval [begin_height, end_height). The function:
- Verifies that the end block hash and all its parents are registered
- Requires a height_proof (containing coinbase transaction and merkle proof) when the previous chain height is not set
- Ensures the chain represents the highest cumulative proof-of-work

### get_status(block_hash: Digest) → BlockStatus

Retrieve information about a block using its hash. Returns:
- registration_timestamp: When the block was registered
- prev_block_digest: Hash of the previous block
- pow: Proof-of-work value

### get_block(height: u64) → Digest

Retrieve the block hash for a given block height in the canonical chain. Returns zero if no block is set at that height.

## Usage Example

Here's a simplified example of how to securely verify a Bitcoin transaction:

1. Register the block containing your transaction and its ancestors using `register_blocks`
2. Update the canonical chain using `update_canonical_chain` to include your block
3. Verify the block's status using `get_status` to check:
   - The registration timestamp (for time-based security)
   - The proof-of-work value meets your security requirements
4. Use `get_block` to confirm the block remains in the canonical chain

## Security Considerations

Since the incentive mechanism is not yet implemented, users should:
- Require high proof-of-work thresholds for sensitive operations
- Wait for multiple confirmations after the target block
- Implement additional application-specific security measures (like checking block timestamp)
- Consider running their own Bitcoin node to verify block submissions

## Fraud Detection and Reporting (Not Yet Implemented)

The fraud detection and reporting mechanism is planned but not yet implemented. When implemented, it will allow:

- Detecting fraud by comparing registered block hashes with Bitcoin Core output for the same height
- Reporting fraud by calling `challenge_block` with correct block headers to replace fraudulent entries
- Receiving a small reward for successful fraud challenges that help maintain chain integrity

## Potential Attack Vectors

Two potential attack vectors exist:

1. Submission of fraudulent block headers: An attacker could attempt to submit false block headers, particularly if no one is actively challenging these submissions or using the valid block hash.

2. 51% attack: Theoretically, an attacker with control over 51% of the Bitcoin hashrate for an extended period could manipulate the relay.

3. Precomputed future blocks: An attacker could precompute fraudulent block headers with future timestamps, avoiding competition with the actual Bitcoin network. This can be mitigated by refusing blocks with timestamps greater than the current Starknet block timestamp.

However, these attacks are generally impractical due to:

- Economic disincentives: The cost of executing such attacks typically outweighs potential gains.
- Detection mechanisms: On-chain detection of 51% attacks allows contracts to implement additional security measures.
- Active monitoring: Honest users and watchers can quickly challenge fraudulent submissions.

The combination of these factors significantly mitigates the risk of successful attacks on the Utu Relay system.
