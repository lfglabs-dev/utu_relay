# Utu Relay

Utu Relay is a Starknet smart contract that enables secure verification of Bitcoin transactions and events. Named after the ancient Sumerian sun god who was believed to see everything that happened in the world, Utu Relay aims to provide a transparent and secure way to bridge Bitcoin data to the Starknet ecosystem.

## Overview

Utu Relay allows anyone to register multiple Bitcoin block hashes starting from any height on Starknet. Smart contracts can access these hashes, along with trust metrics like cumulative proof-of-work and unchallenged time, to verify that any Bitcoin transaction was accepted by the network.

Key features:
- Verify any part of Bitcoin's history
- Avoid redundant verifications
- Strong security guarantees
- Game theory incentives for maintaining accuracy

## Security Guarantees

- Accurate proof-of-work reporting
- Accurate block height reporting
- Strongest proof-of-work chain selection
- Economic incentives for maintaining the most up-to-date chain
- On-chain detection of 51% attacks

## Contract Interface

### register_blocks(starting_height, opt(height_proof), block_headers) → bool

Register a list of Bitcoin blocks, returning `true` if any blocks are successfully registered.

### challenge_block(block_height, proposed_block_headers)

Challenge and potentially update a registered block, with an incentive mechanism for successful updates.

### get_status(block_hash)

Retrieve information about a given `block_hash`, including challenge status, registration timestamp, and cumulative proof-of-work.

## Usage Example

Here's a simplified example of how to securely verify a Bitcoin transaction:

1. Check if the block is unchallenged (or challenged value < 1T hashes) and at least 15 minutes have passed since registration.
2. OR check if more than 24 hours have passed since registration (implying >51% hashrate control for 24+ hours would be needed to manipulate).

Adjust verification requirements based on the specific security needs of your application.

## Fraud Detection and Reporting

- Detect fraud: Compare registered block hash with Bitcoin Core output for the same height.
- Report fraud: Call `challenge_block` with the correct block headers to replace the fraudulent entry.

## Potential Attack Vectors

Two potential attack vectors exist:

1. Submission of fraudulent block headers: An attacker could attempt to submit false block headers, particularly if no one is actively submitting fraud proofs or using the valid block hash.

2. 51% attack: Theoretically, an attacker with control over 51% of the Bitcoin hashrate for an extended period could manipulate the relay.

However, these attacks are generally impractical due to:

- Economic disincentives: The cost of executing such attacks typically outweighs potential gains.
- Detection mechanisms: On-chain detection of 51% attacks allows contracts to implement additional security measures.
- Active monitoring: Honest users and watchers can submit fraud proofs, quickly challenging any false submissions.

The combination of these factors significantly mitigates the risk of successful attacks on the Utu Relay system.

